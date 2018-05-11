# frozen_string_literal: true

module Kracken
  class Registration
    attr_reader :response, :status

    def post(params)
      @response = connection.post do |req|
        req.url '/auth/radius/registration.json'
        req.headers['Content-Type'] = 'application/json'
        req.body = post_body(params).to_json
      end

      @status = response.status

      self
    end

    def body
      if response
        JSON.parse(response.body)
      end
    end

    private

    def post_body(params)
      {
        user: {
          first_name: params["first_name"],
          last_name: params["last_name"],
          email: params["email"],
          password: params["password"],
          password_confirmation: params["password_confirmation"],
          terms_of_service: params["terms_of_service"],
          country: params["country"],
        },
        token: { description: params["token_description"] },
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
