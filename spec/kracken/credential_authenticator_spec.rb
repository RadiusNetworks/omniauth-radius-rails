# frozen_string_literal: true

require 'rails_helper'

module Kracken
  RSpec.describe CredentialAuthenticator do

    let(:json){ Fixtures.auth_hash.to_json }

    def set_request(status, body=nil)
      stub_request(:post, "https://account.radiusnetworks.com/auth/radius/login.json")
        .to_return(status: status, body: body)
    end

    it "parses the json and updates the user" do
      login = CredentialAuthenticator.new
      set_request 200, json

      response = login.fetch "rory@ponds.uk", "secret"
      expect(response.body['uid']).to eq "1"
    end

    it "raises an error on 500" do
      login = CredentialAuthenticator.new

      set_request 500

      expect{login.fetch "rory@ponds.uk", "secret"}
        .to raise_error(RequestError)
    end

    it "raises an error on 404" do
      login = CredentialAuthenticator.new

      set_request 404

      expect{login.fetch("rory@ponds.uk", "secret")}
        .to raise_error(TokenUnauthorized)
    end

  end
end
