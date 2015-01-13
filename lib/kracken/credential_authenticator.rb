module Kracken
  class CredentialAuthenticator
    def fetch(email, password)
      response = connection.post do |req|
        req.url '/auth/radius/login.json'
        req.headers['Content-Type'] = 'application/json'
        req.body = body(email, password).to_json
      end

      # An attempt to raise error when approprate:
      if response.status == 404
        nil
      elsif response.success?
        JSON.parse(response.body)
      else
        raise Kracken::RequestError
      end
    end

    private

    def body(email, password)
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
