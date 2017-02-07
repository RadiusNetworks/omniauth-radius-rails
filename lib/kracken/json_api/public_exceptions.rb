module Kracken
  module JsonApi
    # Error logging methods used by `ActionDispatch::DebugExceptions`
    # https://github.com/rails/rails/blob/v4.2.6/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb
    module ErrorLogging
      def log_error(env, wrapper)
        logger = logger(env)
        return unless logger

        exception = wrapper.exception

        trace = wrapper.application_trace
        trace = wrapper.framework_trace if trace.empty?

        ActiveSupport::Deprecation.silence do
          message = "\n#{exception.class} (#{exception.message}):\n"
          message << exception.annoted_source_code.to_s if exception.respond_to?(:annoted_source_code)
          message << "  " << trace.join("\n  ")
          logger.fatal("#{message}\n\n")
        end
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
      # https://github.com/rails/rails/blob/v4.2.6/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb
      def capture_error(env)
        _, headers, body = response = @app.call(env)

        if headers['X-Cascade'] == 'pass'
          body.close if body.respond_to?(:close)
          raise ActionController::RoutingError,
                "No route matches [#{env['REQUEST_METHOD']}] " \
                "#{env['PATH_INFO'].inspect}"
        end

        response
      rescue Exception => exception
        wrapper = exception_wrapper(env, exception)
        log_error(env, wrapper)
        render_json_error(wrapper)
      end

      if Rails::VERSION::MAJOR < 5
        def exception_wrapper(env, exception)
          ExceptionWrapper.new(env, exception)
        end
      else
        def exception_wrapper(env, exception)
          request = ActionDispatch::Request.new(env)
          backtrace_cleaner = request.get_header('action_dispatch.backtrace_cleaner')
          ExceptionWrapper.new(backtrace_cleaner, exception)
        end
      end

      if Rails.env.production?
        def additional_details(error)
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
          code = Rack::Utils::SYMBOL_TO_STATUS_CODE[status]
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

      def headers(body)
        {
          'Content-Type'   => "application/json; charset=#{ActionDispatch::Response.default_charset}",
          'Content-Length' => body.bytesize.to_s
        }
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
