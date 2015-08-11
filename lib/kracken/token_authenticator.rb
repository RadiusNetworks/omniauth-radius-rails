module Kracken
  class TokenAuthenticator
    attr_reader :response
    def fetch(token)
      @response = connection.get do |req|
        req.url '/auth/radius/user.json'
        req.params['oauth_token'] = token
      end

      if response.status == 401
        raise TokenUnauthorized, "Invalid credentials"
      elsif response.status == 404
        raise TokenUnauthorized, "Invalid credentials"
      elsif !response.success?
        raise RequestError, "Token Authentication Failed. Status: #{response.status} token: #{token}"
      end

      self
    end

    def body
      if response
        JSON.parse(response.body)
      end
    end

    def etag
      if response
        response.headers["etag"]
      end
    end

    private

    def connection
      @connection ||= Faraday.new(url: PROVIDER_URL)
    end

  end
end
