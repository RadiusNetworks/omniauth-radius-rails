module Kracken
  module JsonApi
    class Request < Rack::Request
      include ActionDispatch::Http::Parameters

      attr_reader :env

      def initialize(env)
        @env = env
      end

      def supports_json_format?
        format == :json || accepts.include?(:json) || format_not_set?
      end

      def format_not_set?
        accepts.size == 1 && accepts.first == '*/*'
      end

      def path
        env['json_api.original_path'] ||= (
          env["action_dispatch.original_path"] || env["PATH_INFO"]
        )
      end

      # File actionpack/lib/action_dispatch/http/mime_negotiation.rb
      # Returns the MIME type for the \format used in the request.
      #
      #   GET /posts/5.xml   | request.format => Mime::XML
      #   GET /posts/5.xhtml | request.format => Mime::HTML
      #   GET /posts/5       | request.format => Mime::HTML or MIME::JS, or request.accepts.first
      #
      def format(view_path = [])
        formats.first || Mime::NullType.instance
      end

      def formats
        env["json_api.request.formats"] ||= begin
          params_readable = begin
                              parameters[:format]
                            rescue ActionController::BadRequest
                              false
                            end

          if params_readable
            Array(Mime[parameters[:format]])
          elsif valid_accept_header
            accepts
          # original_format would be set by the ABOVE two conditions
          elsif xhr?
            Mime[:js]
          else
            Mime[:json]
          end
        end
      end

      # Returns the accepted MIME type for the request.
      def accepts
        env["json_api.request.accepts"] ||= begin
          header = env['HTTP_ACCEPT'].to_s.strip

          if header.empty?
            [content_mime_type]
          else
            Mime::Type.parse(header)
          end
        end
      end

      BROWSER_LIKE_ACCEPTS = /,\s*\*\/\*|\*\/\*\s*,/

      def valid_accept_header
        (xhr? && (accept.present? || content_mime_type)) ||
          (accept.present? && accept !~ BROWSER_LIKE_ACCEPTS)
      end

      # The MIME type of the HTTP request, such as Mime::XML.
      #
      # For backward compatibility, the post \format is extracted from the
      # X-Post-Data-Format HTTP header if present.
      def content_mime_type
        env["json_api.request.content_type"] ||= begin
          if env['CONTENT_TYPE'] =~ /^([^,\;]*)/
            Mime::Type.lookup($1.strip.downcase)
          else
            nil
          end
        end
      end

    # File actionpack/lib/action_dispatch/http/request.rb
      def accept
        env["HTTP_ACCEPT"]
      end

      def xhr?
        env['HTTP_X_REQUESTED_WITH'] =~ /XMLHttpRequest/
      end

      # Override Rack's GET method to support indifferent access
      def GET
        @env["action_dispatch.request.query_parameters"] ||=
          ActionDispatch::Request::Utils.deep_munge(normalize_encode_params(super || {}))
      rescue Rack::Utils::ParameterTypeError, Rack::Utils::InvalidParameterError => e
        raise ActionController::BadRequest.new(:query, e)
      end
      alias :query_parameters :GET

      # Override Rack's POST method to support indifferent access
      def POST
        @env["action_dispatch.request.request_parameters"] ||=
          ActionDispatch::Request::Utils.deep_munge(normalize_encode_params(super || {}))
      rescue Rack::Utils::ParameterTypeError, Rack::Utils::InvalidParameterError => e
        raise ActionController::BadRequest.new(:request, e)
      end
      alias :request_parameters :POST
    end
  end
end
