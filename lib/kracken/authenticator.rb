module Kracken
  class Authenticator
    attr_reader :auth_hash

    # @private
    def self.cache
      @cache
    end
    @cache = ActiveSupport::Cache.lookup_store(
      :memory_store,
      size: 5.megabytes,
      expires_in: 1.hour,
      race_condition_ttl: 1.second,
    )

    ## Factory Methods

    # Login the user with their credentails. Used for proxying the
    # authentication to the auth server, normally from a mobile app
    def self.user_with_credentials(email, password)
      auth = Kracken::CredentialAuthenticator.new.fetch(email, password)
      self.new(auth.body).to_app_user
    end

    # Login the user with an auth token. Used for API authentication for the
    # public APIs
    def self.user_with_token(token)
      auth = Kracken::TokenAuthenticator.new.fetch(token)

      # Don't want stale user models being pulled from the cache. So only
      # cache the `user_id`.
      #
      # Don't want to query the database twice. So create a local variable
      # for the user, set it to nil, fetch from cache and only query if there
      # was a cache-hit (thus user is still nil).
      user = nil
      user_id = Authenticator.cache.fetch("#{token}/#{auth.etag}") {
        user = self.new(auth.body).to_app_user
        user.id
      }
      user ||= Kracken.config.user_class.find(user_id)
    end

    def initialize(response)
      @auth_hash = create_auth_hash(response)
    end

    # Convert this Factory to a User object per the host app.
    def to_app_user
      raise MissingUIDError unless auth_hash.uid
      Kracken.config.user_class.find_or_create_from_auth_hash(auth_hash)
    end

    private

    def create_auth_hash(response_hash)
      Hashie::Mash.new({
        provider: response_hash['provider'],
        uid: response_hash['uid'],
        info: response_hash['info'],
        credentials: response_hash['credentials'],
      })
    end

  end
end
