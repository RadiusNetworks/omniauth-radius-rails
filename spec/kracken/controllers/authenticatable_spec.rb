require 'spec_helper'


module Kracken
  module Controllers

    class UserDouble
      def self.find(id)
        self.new
      end
    end

    class BaseControllerDouble
      attr_accessor :session

      def initialize
        @session = {}
      end

      def self.helper_method(*)
      end

      def root_url
        "/"
      end
    end

    class ControllerDouble < BaseControllerDouble
      include Kracken::Controllers::Authenticatable
    end

    describe Authenticatable do
      subject(:controller){ ControllerDouble.new }

      before do
        Kracken.setup do |config|
          config.user_class = UserDouble
          config.provider_url = 'http://rspec'
        end
      end

      context "url helpers" do
        it "#sign_out_path" do
          # Stub the engine instance var that the Application Controller will
          # create in Rails
          allow(controller).to receive(:kracken)
          .and_return(OpenStruct.new(sign_out_path: "test/path"))

          expect(controller.sign_out_path).to eq "test/path"
        end

        it "#sign_up_path" do
          expect(controller.sign_up_path).to eq "http://rspec/users/sign_up"
        end

        it "#sign_in_path" do
          expect(controller.sign_in_path).to eq "/auth/radius"
        end
      end

      context "authenticating user with session" do
        it "authenticate will query for current user" do
          controller.session[:user_id] = 1
          expect(controller.authenticate_user).to be_true
        end

        it "#user_signed_in? will query for current user" do
          controller.session[:user_id] = 1
          expect(controller.user_signed_in?).to be_true
        end

        it "#authenticate! redirects to root_url" do
          allow(controller).to receive(:request).and_return(double(format: nil, fullpath: nil))
          allow(controller).to receive(:redirect_to)

          controller.authenticate_user!

          expect(controller).to have_received(:redirect_to).with("/")
        end
      end

      context "authorization" do
        before do
          allow(controller).to receive(:redirect_to)
          allow(controller).to receive(:request).and_return(double(format: nil, fullpath: nil))
          controller.session[:user_id] = 1
        end

        it "does not redirect to root when user is an admin" do
          allow(controller.current_user).to receive(:admin?).and_return(true)

          controller.authorize_admin!

          expect(controller).to_not have_received(:redirect_to)
        end

        it "redirects to root when user is not an admin" do
          allow(controller.current_user).to receive(:admin?).and_return(false)

          controller.authorize_admin!

          expect(controller).to have_received(:redirect_to).with("/")
        end
      end

      context "#current_user" do
        it "memoizes current user" do
          controller.session[:user_id] = 1
          allow(UserDouble).to receive(:find).and_return(:user_double)
          controller.current_user = :fake_user

          controller.current_user

          expect(UserDouble).to_not have_received(:find)
        end

        it "fetches current user" do
          controller.session[:user_id] = 1
          allow(UserDouble).to receive(:find).and_return(:user_double)

          controller.current_user

          expect(UserDouble).to have_received(:find)
        end
      end

      context "#user_signed_in?" do
        it "is true when there is a user" do
          controller.session[:user_id] = 1
          expect(controller.user_signed_in?).to be_true
        end

        it "is false when no user" do
          controller.session[:user_id] = nil
          expect(controller.user_signed_in?).to be_false
        end
      end

    end
  end
end
