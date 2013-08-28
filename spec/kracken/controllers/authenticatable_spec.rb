require 'spec_helper'


module Kracken
  module Controllers

    class UserDouble
      def self.find(id)
        self.new
      end

      def admin?
        false
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

      context "regardless the of a user session" do
        it "#sign_out_path returns generator's sign_out_path" do
          # Stub the engine instance var that the Application Controller will
          # create in Rails
          allow(controller).to receive(:kracken)
          .and_return(OpenStruct.new(sign_out_path: "test/path"))

          expect(controller.sign_out_path).to eq "test/path"
        end

        it "#sign_up_path returns url for account server" do
          expect(controller.sign_up_path).to eq "http://rspec/users/sign_up"
        end

        it "#sign_in_path returns auth/radius" do
          expect(controller.sign_in_path).to eq "/auth/radius"
        end
      end

      context "when no users are logged in" do
        it "#authenticate! redirects to root_url" do
          allow(controller).to receive(:request).and_return(double(format: nil, fullpath: nil))
          allow(controller).to receive(:redirect_to)

          controller.authenticate_user!

          expect(controller).to have_received(:redirect_to).with("/")
        end

        it "#user_signed_in? is false" do
          expect(controller.user_signed_in?).to be_false
        end

      end

      context "when a user is logged in" do
        before do
          controller.session[:user_id] = 1
        end

        it "#user_signed_in? is true" do
          expect(controller.user_signed_in?).to be_true
        end

        it "#authenticate_user is true" do
          controller.session[:user_id] = 1
          expect(controller.authenticate_user).to be_true
        end

        it "#user_signed_in? is true" do
          expect(controller.user_signed_in?).to be_true
        end

        it "#redirects to root when user is not an admin" do
          allow(controller).to receive(:request).and_return(double(format: nil, fullpath: nil))
          allow(controller).to receive(:redirect_to)

          controller.authorize_admin!

          expect(controller).to have_received(:redirect_to).with("/")
        end

        it "#current_user memoizes current user" do
          allow(UserDouble).to receive(:find).and_return(:user_double)
          controller.current_user = :fake_user

          controller.current_user

          expect(UserDouble).to_not have_received(:find)
        end

        it "#current_user fetches current user" do
          allow(UserDouble).to receive(:find).and_return(:user_double)

          controller.current_user

          expect(UserDouble).to have_received(:find)
        end
      end

      context "when an admin user is logged in" do
        before do
          controller.session[:user_id] = 1
          allow(controller.current_user).to receive(:admin?).and_return(true)
        end

        it "does not redirect to root when user is an admin" do
          allow(controller).to receive(:redirect_to)
          allow(controller).to receive(:request).and_return(double(format: nil, fullpath: nil))

          controller.authorize_admin!

          expect(controller).to_not have_received(:redirect_to)
        end
      end

    end
  end
end
