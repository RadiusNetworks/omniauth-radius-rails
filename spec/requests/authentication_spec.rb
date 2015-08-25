require 'spec_helper'

module Kracken
  RSpec.describe "authenticatable resource requests", type: :request do
    let(:token_expiry) {1441650437}
    let(:auth_hash) {
      {
        "credentials"=>{
          "token"=>"8675c978497731f60ecdea6787c4316b",
          "refresh_token"=>"7340329b1e0d7a6749bdfb2ca1597360",
          "expires_at"=>token_expiry,
          "expires"=>true
        }
      }
    }

    def headers_with_token(token)
      { 'HTTP_AUTHORIZATION'=>"Token token=\"#{token}\"" }
    end

    it "is redirected to the oauth server if there is no current user" do
      get "/welcome/secure_page"
      expect(response).to redirect_to("/auth/radius?origin=%2Fwelcome%2Fsecure_page")
    end

    it "returns an unprotected page if there is no current user" do
      get "/welcome/index"
      expect(response.status).to be 200
    end

    it "sets :token_expires_at in the session" do
      OmniAuth.config.mock_auth[:radius] = OmniAuth::AuthHash.new(auth_hash)
      get "/auth/radius/callback"
      expect(request.session[:token_expires_at]).to eq(Time.zone.at(token_expiry))
    end
  end
end
