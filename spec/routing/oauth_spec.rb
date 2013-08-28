require 'spec_helper'

module Kracken
    describe "Kracken OAuth Routes" do
      routes { Kracken::Engine.routes }

      it "sign_out routes to sessions" do
       { :get => '/sign_out/' }
         .should route_to controller: 'kracken/sessions',
                          action: 'destroy'
      end

      it "sign_out routes to sessions" do
       { :get => '/radius/callback/' }
         .should route_to controller: 'kracken/sessions',
                          provider: "radius",
                          action: 'create'
      end
    end
end
