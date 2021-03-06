# frozen_string_literal: true

module Kracken
  module Controllers
    module TokenAuthenticatable
      # @private
      def self.cache
        @cache
      end

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
        def request_http_token_authentication(realm = 'Application', _message = nil)
          headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
          raise TokenUnauthorized, "Invalid Credentials"
        end
      else
        def request_http_token_authentication(realm = 'Application')
          headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
          raise TokenUnauthorized, "Invalid Credentials"
        end
      end

    module_function

      # @private
      def auth_cache_key(token)
        # This key must **ALWAYS** be generated and stored either in-memory or
        # "securely" on the server. Treat this like the Rails / Devise secret
        # key.
        #
        # If in the future we move back to an external cache (say Redis) for
        # the cached auth token storage this must still remain **ONLY** on the
        # server.
        key = TokenAuthenticatable.cache.fetch("KEY", AUTH_KEY_OPTS) {
          # Clear all existing data generated by previous key
          clear_auth_cache
          # HMAC-SHA256 takes a maximum key size of 64-bytes
          # See https://crypto.stackexchange.com/questions/34864/key-size-for-hmac-sha256/34866#34866
          SecureRandom.random_bytes(64)
        }
        OpenSSL::HMAC.digest("SHA256", key, token)
      end

      def cache_valid_auth(token, force: false, &generate_cache)
        cache_key = auth_cache_key(token)
        val, nonce, hmac = TokenAuthenticatable.cache.read(cache_key) unless force
        val = nil unless hmac == OpenSSL::HMAC.digest("SHA256", "#{nonce}#{token}", val.to_s)
        val ||= store_valid_auth(token, cache_key, &generate_cache)
        shallow_freeze(val)
      end

      def clear_auth_cache
        TokenAuthenticatable.cache.clear
      end

      def shallow_freeze(val)
        return val if val.frozen?
        val.each { |_k, v| v.freeze }.freeze
      end

      def store_valid_auth(token, cache_key = auth_cache_key(token))
        return unless (val = yield(token))

        # HMAC-SHA256 takes a maximum of 64-bytes for the key. When data is
        # longer it is hashed, truncating to 32-bytes. We add the nonce here to
        # force us over that 64-byte limit, thus hashing the result. This is to
        # ensure at least 32-bytes of entropy from the token. This HMAC is
        # mearly meant as a hash collision guard, not as added security.
        nonce = SecureRandom.random_bytes(64)
        hmac = OpenSSL::HMAC.digest("SHA256", "#{nonce}#{token}", val.to_s)
        TokenAuthenticatable.cache.write cache_key,
                                         [val, nonce, hmac].freeze,
                                         CACHE_TTL_OPTS
        val
      end

    private

      AUTH_KEY_OPTS = {
        expires_in: 5.minutes, # Rotate key relatively frequently
        race_condition_ttl: 1.second,
      }.freeze

      CACHE_TTL_OPTS = {
        expires_in: ENV.fetch("KRACKEN_TOKEN_TTL", 1.minute).to_i,
        race_condition_ttl: 1.second,
      }.freeze

      @cache = ActiveSupport::Cache.lookup_store(
        :memory_store,
        CACHE_TTL_OPTS.merge(size: 5.megabytes),
      )

      # `authenticate_or_request_with_http_token` is a nice Rails helper:
      # http://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token/ControllerMethods.html#method-i-authenticate_or_request_with_http_token
      def authenticate_user_with_token!
        munge_header_auth_token!

        authenticate_or_request_with_http_token(realm) { |token, _options|
          # Attempt to reduce ivar namespace conflicts with controllers
          @_auth_info = cache_valid_auth(token) {
            if (@current_user = Authenticator.user_with_token(token))
              { id: @current_user.id, team_ids: @current_user.team_ids }
            end
          }
        }
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
    end

  end
end
