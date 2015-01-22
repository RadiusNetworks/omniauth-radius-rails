module Kracken
  module Controllers
    module TokenAuthenticatable
      def self.included(base)
        base.define_singleton_method(:realm) do |realm = nil|
          realm ||= (superclass.try(:realm) || 'Application')
          @realm = realm
        end

        base.instance_exec do
          before_action :authenticate_user_with_token!
          helper_method :current_user
        end
      end

      attr_reader :current_user

      private

      # `authenticate_or_request_with_http_token` is a nice Rails helper:
      # http://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token/ControllerMethods.html#method-i-authenticate_or_request_with_http_token
      def authenticate_user_with_token!
        unless current_user
          munge_header_auth_token!

          authenticate_or_request_with_http_token(realm) { |token, _options|
            # Attempt to reduce namespace conflicts with controllers which may access
            # an team instance for display.
            @current_user = Authenticator.user_with_token(token)
          }
        end
      end

      # Make it **explicit** that we are munging the `token` param with the
      # authorization header.
      #
      # Yes, this is very much a hack. However, it makes it clear what we are
      # doing. It also defines a single authoritative source for how we handle
      # authorization alternatives. This then allows other Rails and app code to
      # work normally with authorization headers; without having to repeat or
      # transfer the knowledge about also checking for the params.
      def munge_header_auth_token!
        return unless params[:token]
        request.env['HTTP_AUTHORIZATION'] = "Token token=\"#{params[:token]}\""
      end

      # Customize the `authenticate_or_request_with_http_token` process:
      # http://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token/ControllerMethods.html#method-i-request_http_token_authentication
      def request_http_token_authentication(realm = 'Application')
        # Modified from https://github.com/rails/rails/blob/60d0aec7/actionpack/lib/action_controller/metal/http_authentication.rb#L490-L499
        headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
        render json: { error: 'HTTP Token: Access denied.' }, status: :unauthorized
      end

      def realm
        self.class.realm
      end
    end

  end
end
