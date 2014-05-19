require 'spec_helper'

module Kracken
  describe "requests to and authenticatable resource", type: :request do
    it "is redirected to the oauth server if there is no current user" do
      get "/welcome/index"
      expect(response).to redirect_to("/auth/radius?origin=%2Fwelcome%2Findex")
    end

    it "is redirected to the oauth server if there is no current user" do
      authenticate_request!
      get "/welcome/index"
      expect(response.status).to be 200
    end
  end
end
