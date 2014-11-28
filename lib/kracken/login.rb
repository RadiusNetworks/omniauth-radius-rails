module Kracken
  class Login
    attr_reader :email, :password

    def initialize(email, password)
      @email = email
      @password = password
    end

    def login!
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

    def body
      {
        user: {
          email: email,
          password: password,
        },
        application: {
          name: config.app_id,
          secret:  config.app_secret,
        },
      }
    end

    def login
      response = connection.post do |req|
        req.url '/auth/radius/login.json'
        req.headers['Content-Type'] = 'application/json'
        req.body = body.to_json
      end

      create_auth_hash JSON.parse(response.body)
    end

    def connection
      @connection ||= Faraday.new(:url => PROVIDER_URL)
    end

    def auth_hash
      @auth_hash ||= login
    end

    def user_class
      Kracken.config.user_class
    end
  end
end
