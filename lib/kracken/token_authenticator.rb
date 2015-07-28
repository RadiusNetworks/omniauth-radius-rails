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
        raise RequestError
      end

      self
    end

    def body
      JSON.parse(response.body)
    end

    def etag
      response.headers["etag"]
    end

    private

    def connection
      @connection ||= Faraday.new(url: PROVIDER_URL)
    end

  end
end
