module Kracken
  class TokenAuthenticator

    def fetch(token)
      response = connection.get do |req|
        req.url '/auth/radius/user.json'
        req.params['oauth_token'] = token
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

    def connection
      @connection ||= Faraday.new(url: PROVIDER_URL)
    end
  end
end
