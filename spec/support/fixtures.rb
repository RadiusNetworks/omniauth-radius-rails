# frozen_string_literal: true

module Kracken
  module Fixtures
    # Fixtures gathered from a request kracken server running locally
    def self.auth_hash
      {
        "provider"=>"radius",
        "uid"=>"1",
        "info"=>
        {
          "first_name"=>"admin",
          "last_name"=>"admin",
          "email"=>"admin@radiusnetworks.com",
          "uid"=>1,
          "confirmed"=>true,
          "organizations"=>[
            {"uid"=>1, "name"=>"Radius Networks"},
          ],
          "organization_roles"=>[
            {"uid"=>1, "organization_id"=>1, "role"=>"owner"},
          ],
          "services"=>[
            {"uid"=>1, "slug"=>"pickup", "name"=>"FlyBuy Pickup"},
          ],
          "service_roles"=>[
            {"uid"=>1, "role"=>"owner", "team_id"=>1, "service_id"=>1, "organization_id"=>1},
          ],
          "teams"=>[
            {"id"=>1, "name"=>"Radius Networks", "uid"=>1},
            {"id"=>2, "name"=>"TARDIS", "uid"=>2}
          ],
          "admin"=>true,
          "subscription_level"=>"basic"
        },
        "credentials"=>
        {
          "token"=>"22b432decfbe36c97ce7f6c7d10414b0",
          "refresh_token"=>"0ba439c3f69f577598fe2cd189527474",
          "expires_at"=>1422391358,
          "expires"=>true
        }
      }
    end
  end
end
