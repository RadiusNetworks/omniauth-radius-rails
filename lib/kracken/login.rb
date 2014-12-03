module Kracken

  class Login
    attr_reader :email, :password

    def initialize(email, password)
      @email = email
      @password = password
    end

    def login_and_create_user!
      auth_hash = perform_login

      auth_hash ? user_class.find_or_create_from_auth_hash(auth_hash) : nil
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
          name: app_id,
          secret:  app_secret,
        },
      }
    end

    def perform_login
      response = connection.post do |req|
        req.url '/auth/radius/login.json'
        req.headers['Content-Type'] = 'application/json'
        req.body = body.to_json
      end

      if response.success?
        create_auth_hash JSON.parse(response.body)
      else
        nil
      end
    end

    def connection
      @connection ||= Faraday.new(url: PROVIDER_URL)
    end

    def user_class
      Kracken.config.user_class
    end

    def app_id
      Kracken.config.app_id
    end

    def app_secret
      Kracken.config.app_secret
    end
  end
end
