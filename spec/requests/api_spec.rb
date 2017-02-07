require 'rails_helper'

module Kracken
  RSpec.describe 'token authenticatable resource requests', type: :request do

    def headers_with_token(token)
      {
        'HTTP_AUTHORIZATION'=>"Token token=\"#{token}\"",
        'HTTP_ACCEPT' => 'application/json',
      }
    end

    # Temporary work around while we support versions of Rails before 4
    if Rails::VERSION::MAJOR >= 5
      def request_resource(path, params: {}, headers: {})
        get api_index_path, params: params, headers: headers
      end
    else
      def request_resource(path, params: {}, headers: {})
        get api_index_path, params, headers
      end
    end

    let(:json){ Fixtures.auth_hash.to_json }

    describe "authenticatable resource" do
      it "will raise error if there is no token" do
        expect {
          request_resource api_index_path
        }.to raise_error Kracken::TokenUnauthorized
      end

      it "is redirected to the oauth server if there is no current user" do
        stub_request(:get, "https://account.radiusnetworks.com/auth/radius/user.json?oauth_token=123")
          .to_return(status: 200, body: json)

        request_resource api_index_path, headers: headers_with_token("123")

        expect(response.status).to be 200
      end
    end

    describe "content negotiation" do
      it "will raise an error with an incorrect accept header" do
        stub_request(:get, "https://account.radiusnetworks.com/auth/radius/user.json?oauth_token=123")
          .to_return(status: 200, body: json)

        auth_headers = headers_with_token("123")
        auth_headers.delete 'HTTP_ACCEPT'
        expect {
          request_resource api_index_path, headers: auth_headers
        }.to raise_error ActionController::UnknownFormat
      end
    end
  end
end
