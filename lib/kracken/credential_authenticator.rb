# frozen_string_literal: true

module Kracken
  class CredentialAuthenticator
    attr_reader :response

    def fetch(email, password)
      @response = connection.post do |req|
        req.url '/auth/radius/login.json'
        req.headers['Content-Type'] = 'application/json'
        req.body = post_body(email, password).to_json
      end

      if response.status == 401
        raise TokenUnauthorized, "Invalid credentials"
      elsif response.status == 404
        raise TokenUnauthorized, "Invalid credentials"
      elsif !response.success?
        raise RequestError
      end

      self
    end

    def body
      if response
        JSON.parse(response.body)
      end
    end

    private

    def post_body(email, password)
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

    def connection
      @connection ||= Faraday.new(url: PROVIDER_URL)
    end

    def app_id
      Kracken.config.app_id
    end

    def app_secret
      Kracken.config.app_secret
    end
  end
end
