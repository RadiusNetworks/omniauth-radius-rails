# frozen_string_literal: true

module Kracken
  module JsonApi
    # Error logging methods used by `ActionDispatch::DebugExceptions`
    # https://github.com/rails/rails/blob/v8.0.0/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb
    module ErrorLogging
      def log_error(env, wrapper)
        logger = logger(env)
        return unless logger

        exception = wrapper.exception

        trace = wrapper.application_trace
        trace = wrapper.framework_trace if trace.empty?

        message = +"\n#{exception.class} (#{exception.message}):\n"
        message << annotated_source(wrapper)
        message << "  " << trace.join("\n  ")
        logger.fatal("#{message}\n\n")
      end

      # One line per source line, ending in a newline so the trace that
      # follows starts on its own line (as `DebugExceptions` logs it).
      def annotated_source(wrapper)
        source = Array(wrapper.annotated_source_code)
        source.empty? ? "" : "#{source.join("\n")}\n"
      end

      def logger(env)
        env['action_dispatch.logger'] || stderr_logger
      end

      def stderr_logger
        @stderr_logger ||= ActiveSupport::Logger.new($stderr)
      end
    end

    class PublicExceptions
      include ErrorLogging

      def initialize(app)
        @app = app
      end

      def call(env)
        if JsonApi.has_path?(ActionDispatch::Request.new(env))
          capture_error(env)
        else
          @app.call(env)
        end
      end

      # Use similar logic to how `ActionDispatch::DebugExceptions` captures
      # routing errors.
      # https://github.com/rails/rails/blob/v8.0.0/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb
      def capture_error(env)
        _, headers, body = response = @app.call(env)

        # Rack 3 lower-cases response header names. `ActionDispatch::Constants`
        # resolves to whichever spelling the loaded Rack uses, so this matches
        # on both. Hard-coding "X-Cascade" silently stops matching under Rack 3,
        # which turns routing errors back into bare 404s.
        if headers[ActionDispatch::Constants::X_CASCADE] == 'pass'
          body.close if body.respond_to?(:close)
          raise ActionController::RoutingError,
                "No route matches [#{env['REQUEST_METHOD']}] " \
                "#{env['PATH_INFO'].inspect}"
        end

        response
      rescue Exception => exception # rubocop:disable Lint/RescueException
        wrapper = exception_wrapper(env, exception)
        log_error(env, wrapper)
        render_json_error(wrapper)
      end

      def exception_wrapper(env, exception)
        request = ActionDispatch::Request.new(env)
        backtrace_cleaner = request.get_header('action_dispatch.backtrace_cleaner')
        ExceptionWrapper.new(backtrace_cleaner, exception)
      end

      if Rails.env.production?
        def additional_details(_error)
          {}
        end
      else
        def additional_details(error)
          {
            backtrace: error.backtrace,
          }
        end
      end

      def show_error_details?(wrapper)
        wrapper.is_details_exception? ||
          Rails.application.config.consider_all_requests_local ||
          (Rails.env.test? && wrapper.status_code == 500)
      end

      def error_as_json(wrapper)
        return {} unless show_error_details?(wrapper)
        error = wrapper.exception
        {
          # "`detail`" - A human-readable explanation specific to this occurrence
          #              of the problem.
          detail: error.message,
          # Additional members **MAY** be specified within error objects.
        }.merge(additional_details(error))
      end

      def numeric_code(status)
        case status
        when Symbol
          # `Rack::Utils.status_code` still understands the symbols Rack 3.1
          # renamed (e.g. `:unprocessable_entity`), which are no longer present
          # in `SYMBOL_TO_STATUS_CODE`. It raises `ArgumentError` on genuinely
          # unknown symbols, which is this method's contract anyway.
          return Rack::Utils.status_code(status)
        when Integer
          code = status
        when String
          code = status.to_i
          code = nil if code == 0
        end
        raise ArgumentError, "Invalid response type #{status.inspect}" if code.nil?
        code
      end

      def render_json_error(wrapper)
        body = json_body(wrapper)
        [ wrapper.status_code, headers(body), [body] ]
      end

      def json_body(wrapper)
        # Error objects are specialized resource objects that **MAY** be returned
        # in a response to provide additional information about problems
        # encountered while performing an operation. Error objects **SHOULD** be
        # returned as a collection keyed by "`errors`" in the top level of a JSON
        # API document, and **SHOULD NOT** be returned with any other top level
        # resources.
        {
          errors: [
            status_code_as_json(wrapper.status_code).merge(error_as_json(wrapper))
          ]
        }.to_json
      end

      # Rack 3 requires lower-case response header names, Rack 2 conventionally
      # uses capitalized ones. `ActionDispatch::Response::Headers` is the
      # case-insensitive hash Rails itself uses, and resolves to the right
      # implementation for the loaded Rack, so this is correct on both.
      def headers(body)
        headers = ActionDispatch::Response::Headers.new
        headers['Content-Type'] =
          "application/json; charset=#{ActionDispatch::Response.default_charset}"
        headers['Content-Length'] = body.bytesize.to_s
        headers
      end

      def status_code_as_json(status)
        code = numeric_code(status)
        title = Rack::Utils::HTTP_STATUS_CODES.fetch(code) {
          raise ArgumentError, "Invalid response type #{status}"
        }
        {
          # "`status`" - The HTTP status code applicable to this problem, expressed
          #              as a string value.
          status: code.to_s,
          # "`title`" - A short, human-readable summary of the problem. It **SHOULD
          #             NOT** change from occurrence to occurrence of the problem,
          #             except for purposes of localization.
          title: title,
        }
      end
    end
  end
end
