module Kracken
  class Updater
    attr_reader :token

    def initialize(oauth_token)
      @token = oauth_token
    end

    def refresh_with_oauth!
      user_class.find_or_create_from_auth_hash(auth_hash)
    end

    private

    def create_auth_hash(response_hash)
      Hashie::Mash.new({
        provider: response_hash['provider'],
        uid: response_hash['attributes']['uid'],
        extra: { raw_info: response_hash }
      })
    end

    def fetch
      response = Faraday.get "#{PROVIDER_URL}/auth/radius/user.json?oauth_token=#{token}"
      create_auth_hash JSON.parse(response.body)
    end

    def auth_hash
      @auth_hash ||= fetch
    end

    def user_class
      Kracken.config.user_class
    end
  end
end
