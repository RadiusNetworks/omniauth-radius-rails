require 'spec_helper'

module Kracken
    describe "Kracken OAuth Routes", type: :routing do
      routes { Kracken::Engine.routes }

      it "sign_out routes to sessions" do
       expect({ :get => '/sign_out/' })
         .to route_to controller: 'kracken/sessions',
                          action: 'destroy'
      end

      it "sign_out routes to sessions" do
       expect({ :get => '/radius/callback/' })
         .to route_to controller: 'kracken/sessions',
                          provider: "radius",
                          action: 'create'
      end
    end
end
