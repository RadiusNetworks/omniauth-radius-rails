require 'spec_helper'

module Kracken
  RSpec.describe 'token authenticatable resource requests', type: :request do

    def headers_with_token(token)
      { 'HTTP_AUTHORIZATION'=>"Token token=\"#{token}\"" }
    end

    let(:json){ Fixtures.auth_hash.to_json }

    describe "requests to and authenticatable resource", type: :request do
      it "Renders unauthorized if there is no token" do
        get api_index_path
        expect(response.status).to eq(401)
      end

      it "is redirected to the oauth server if there is no current user" do
        stub_request(:get, "https://account.radiusnetworks.com/auth/radius/user.json?oauth_token=123")
          .to_return(status: 200, body: json)

        get api_index_path, nil, headers_with_token("123")

        expect(response.status).to be 200
      end
    end
  end
end
