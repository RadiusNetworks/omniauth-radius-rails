require 'spec_helper'


module Kracken
  module Controllers

    class BaseControllerDouble
      def self.helper_method(*)
      end
    end

    class ControllerDouble < BaseControllerDouble
      include Kracken::Controllers::Authenticatable
    end

    describe Authenticatable do
      subject(:controller){ ControllerDouble.new }

      it "returns the sign_out_path" do
        expect(controller.sign_out_path).to eq "hi"
      end
    end
  end
end
