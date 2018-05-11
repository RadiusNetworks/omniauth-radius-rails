# frozen_string_literal: true

require 'rails_helper'

module Kracken
  RSpec.describe Registration do

    let(:valid_registration) {
      {
        user: {
          first_name: "Rory",
          last_name: "Williams",
          email: "rory@ponds.uk",
          password: "I died and turned into a Roman.",
          password_confirmation: "I died and turned into a Roman.",
          terms_of_service: true,
          country: 'United States',
        },
        application: { name: "client app_id", secret: "client app_secret" },
        token: { description: "RSpec Test Token" }
      }
    }

    def set_request(status, body=nil)
      stub_request(:post, "https://account.radiusnetworks.com/auth/radius/registration.json")
        .to_return(status: status, body: body)
    end

    it "parses the json and returns the token" do
      reg = Registration.new
      set_request 200, {
        token: "I am a token",
        email: "joe2@tester.com"
      }.to_json

      response = reg.post valid_registration
      expect(response.body['token']).to eq "I am a token"
    end

    it "proxies any errors back to the caller" do
      reg = Registration.new

      set_request 500, {
        message: ["What is that thing on your head?"]
      }.to_json
      response = reg.post valid_registration
      expect(response.body['message']).to eq(["What is that thing on your head?"])
    end

  end
end
