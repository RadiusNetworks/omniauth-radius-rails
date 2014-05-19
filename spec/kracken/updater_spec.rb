require 'spec_helper'

module Kracken
  describe Config do
    let(:json){ <<-EOF
      {
        "provider": "radius",
        "id": "2",
        "attributes": {
          "id": 2,
          "email": "admin@radiusnetworks.com",
          "admin": true,
          "first_name": "admin",
          "last_name": "admin",
          "status": "Active",
          "expiration_date": "2014-12-03",
          "created_at": "2013-12-03T19:27:22.433Z",
          "updated_at": "2013-12-03T20:28:19.955Z",
          "company": null,
          "country": "United States",
          "terms_of_service": true,
          "initial_service_code": null,
          "initial_plan_code": null,
          "customer_id": "cus_33VtUAeh7B43Ou",
          "subscription_id": 2,
          "uid": 2,
          "accounts": [],
          "plans": [
            {
              "feature_level": "pro",
              "code": "proximitykit"
            }
          ]
        }
      }
      EOF
    }
    let(:response){ OpenStruct.new(body:json) }

    class FakeUser
      def find_or_create_from_auth_hash(auth)
        uid auth.uid
        provider auth.provider
      end
    end

    it "parses the json and updates the user" do
      allow(Faraday).to receive(:get).and_return(response)
      updater = Updater.new :fake_token

      user_double = FakeUser.new
      allow(user_double).to receive(:uid)
      allow(user_double).to receive(:provider)
      allow(updater).to receive(:user_class).and_return(user_double)

      updater.refresh_with_oauth!

      expect(user_double).to have_received(:uid).with(2)
    end


  end
end

