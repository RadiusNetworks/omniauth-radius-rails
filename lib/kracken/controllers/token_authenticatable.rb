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

      # Customize the `authenticate_or_request_with_http_token` process:
      # http://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token/ControllerMethods.html#method-i-request_http_token_authentication
      #
      # Modified from https://github.com/rails/rails/blob/60d0aec7/actionpack/lib/action_controller/metal/http_authentication.rb#L490-L499
      if Rails::VERSION::MAJOR >= 5
        def request_http_token_authentication(realm = 'Application', message = nil)
          headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
          raise TokenUnauthorized, "Invalid Credentials"
        end
      else
        def request_http_token_authentication(realm = 'Application')
          headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
          raise TokenUnauthorized, "Invalid Credentials"
        end
      end

    private

      CACHE_TTL_OPTS = {
        expires_in: ENV.fetch("KRACKEN_TOKEN_TTL", 1.minute).to_i,
        race_condition_ttl: 1.second,
      }.freeze

      # `authenticate_or_request_with_http_token` is a nice Rails helper:
      # http://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token/ControllerMethods.html#method-i-authenticate_or_request_with_http_token
      def authenticate_user_with_token!
        munge_header_auth_token!

        authenticate_or_request_with_http_token(realm) { |token, _options|
          # Attempt to reduce ivar namespace conflicts with controllers
          @_auth_info = cache_valid_auth(token) {
            if @current_user = Authenticator.user_with_token(token)
              { id: @current_user.id, team_ids: @current_user.team_ids }
            end
          }
        }
      end

      def cache_valid_auth(token, &generate_cache)
        cache_key = "auth/token/#{token}"
        val = Rails.cache.read(cache_key)
        val ||= store_valid_auth(cache_key, &generate_cache)
        shallow_freeze(val)
      end

      def shallow_freeze(val)
        # `nil` is frozen in Ruby 2.2 but not in Ruby 2.1
        return val if val.frozen? || val.nil?
        val.each { |_k, v| v.freeze }.freeze
      end

      def current_auth_info
        @_auth_info ||= {}
      end

      def current_team_ids
        current_auth_info[:team_ids]
      end

      def current_user
        @current_user ||= Kracken.config.user_class.find(current_auth_info[:id])
      end

      def current_user_id
        current_auth_info[:id]
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

      def realm
        self.class.realm
      end

      def store_valid_auth(cache_key)
        val = yield
        Rails.cache.write(cache_key, val, CACHE_TTL_OPTS) if val
        val
      end
    end

  end
end
