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
      end
    end

    it "parses the json and updates the user" do
      Faraday.stub(:post).and_return(response)
      login = Login.new "rory@ponds.uk", "secret"

      user_double = FakeUser.new
      allow(user_double).to receive(:uid)
      conn_double = double(:connection)
      allow(conn_double).to receive(:post).and_return(OpenStruct.new body: json)
      allow(login).to receive(:user_class).and_return(user_double)
      allow(login).to receive(:connection).and_return(conn_double)

      login.login!


      expect(user_double).to have_received(:uid).with(2)
    end


  end
end

