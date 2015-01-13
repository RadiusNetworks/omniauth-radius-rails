require 'spec_helper'

module Kracken
  RSpec.describe "authenticatable resource requests", type: :request do
    def headers_with_token(token)
      { 'HTTP_AUTHORIZATION'=>"Token token=\"#{token}\"" }
    end

    it "is redirected to the oauth server if there is no current user" do
      get "/welcome/secure_page"
      expect(response).to redirect_to("/auth/radius?origin=%2Fwelcome%2Fsecure_page")
    end

    it "is redirected to the oauth server if there is no current user" do
      get "/welcome/index"
      expect(response.status).to be 200
    end

  end
end
