# frozen_string_literal: true

require 'rails_helper'

module Kracken
  RSpec.describe TokenAuthenticator do
    let(:json){ Fixtures.auth_hash.to_json }

    def set_request(status, body=nil)
      stub_request(:get, "https://account.radiusnetworks.com/auth/radius/user.json?oauth_token=secret")
        .to_return(status: status, body: body)
    end

    it "parses the json and updates the user" do
      login = TokenAuthenticator.new
      set_request 200, json

      response = login.fetch "secret"
      expect(response.body['uid']).to eq "1"
    end

    it "raises an error on 500" do
      login = TokenAuthenticator.new

      set_request 500

      expect{login.fetch "secret"}.to raise_error(RequestError)
    end

    it "raises an error on 404" do
      login = TokenAuthenticator.new

      set_request 404

      expect{login.fetch "secret"}.to raise_error(TokenUnauthorized)
    end

  end
end

