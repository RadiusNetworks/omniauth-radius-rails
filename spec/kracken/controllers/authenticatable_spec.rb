# frozen_string_literal: true

require 'rails_helper'


module Kracken
  module Controllers

    class ControllerDouble < BaseControllerDouble
      include Kracken::Controllers::Authenticatable
    end

    RSpec.describe Authenticatable do
      subject(:controller){ ControllerDouble.new }

      before do
        Kracken.setup do |config|
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

        it "#sign_up_path appends query parameters" do
          expect(controller.sign_up_path query: 'param').to eq "http://rspec/users/sign_up?query=param"
        end

        it "#sign_in_path returns auth/radius" do
          expect(controller.sign_in_path).to eq "/auth/radius"
        end
      end

      context "when no users are logged in" do
        let(:html) { Mime::Type.lookup("text/html") }
        let(:json) { Mime::Type.lookup("application/json") }
        let(:js) { Mime::Type.lookup("application/javascript") }

        it "#authenticate! redirects to root_url for format html" do
          allow(controller).to receive(:request).and_return(double(format: html, fullpath: nil))
          allow(controller).to receive(:redirect_to)

          controller.authenticate_user!

          expect(controller).to have_received(:redirect_to).with("/")
        end

        it "#user_signed_in? is false" do
          expect(controller.user_signed_in?).to be_falsey
        end

        it "#authenticate! doesn't redirect for format json" do
          allow(controller).to receive(:request).and_return(double(format: json, fullpath: nil))
          allow(controller).to receive(:redirect_to)
          allow(controller).to receive(:render)

          controller.authenticate_user!

          expect(controller).not_to have_received(:redirect_to)
          expect(controller).to have_received(:render)
        end

        it "#authenticate! doesn't redirect for format js" do
          allow(controller).to receive(:request).and_return(double(format: js, fullpath: nil))
          allow(controller).to receive(:redirect_to)
          allow(controller).to receive(:head)

          controller.authenticate_user!

          expect(controller).not_to have_received(:redirect_to)
          expect(controller).to have_received(:head).with(:unauthorized)
        end

      end

      context "when a user is logged in" do
        before do
          controller.session[:user_id] = 1
          User.find_or_create_from_auth_hash({"uid" => 1})
        end

        it "#user_signed_in? is true" do
          expect(controller.user_signed_in?).to be_truthy
        end

        it "#authenticate_user is true" do
          expect(controller.authenticate_user).to be_truthy
        end

        it "#user_signed_in? is true" do
          expect(controller.user_signed_in?).to be_truthy
        end

        it "#current_user memoizes current user" do
          allow(User).to receive(:find).and_return(:user_double)
          controller.current_user = :fake_user

          controller.current_user

          expect(User).to_not have_received(:find)
        end

        it "#current_user fetches current user" do
          allow(User).to receive(:find).and_return(:user_double)

          controller.current_user

          expect(User).to have_received(:find)
        end


        it "redirects to sign-in when token has expired" do
          allow(controller).to receive(:request).and_return(double(format: nil, fullpath: nil))
          allow(controller).to receive(:redirect_to)
          controller.session[:token_expires_at] = Time.zone.now - 5.minutes
          controller.authenticate_user!
          expect(controller).to have_received(:redirect_to)
        end

        it "authenticates user when token has not expired" do
          allow(controller).to receive(:request).and_return(double(format: nil, fullpath: nil))
          allow(controller).to receive(:redirect_to)
          controller.session[:token_expires_at] = Time.zone.now + 5.minutes
          controller.authenticate_user!
          expect(controller).to_not have_received(:redirect_to)
        end

        context "user cache key" do
          it "ends session and redirects if stored key does not match session key" do
            controller.session[:user_cache_key] = "123"
            controller.session[:user_uid] = "123"

            allow(controller).to receive(:request).and_return(double(format: nil, fullpath: nil))
            allow(controller).to receive(:redirect_to)
            allow(Kracken::SessionManager).to receive(:get).and_return("456")

            expect(controller).to receive(:redirect_to).with("/")
            expect(controller.session).to receive(:delete).with(:user_id)
            expect(controller.session).to receive(:delete).with(:user_uid)
            expect(controller.session).to receive(:delete).with(:user_cache_key)

            controller.handle_user_cache_key!
          end

          it "does nothing if session keys match" do
            controller.session[:user_cache_key] = "123"
            controller.session[:user_uid] = "123"

            allow(controller).to receive(:request).and_return(double(format: nil, fullpath: nil))
            allow(controller).to receive(:redirect_to)
            allow(Kracken::SessionManager).to receive(:get).and_return("123")

            expect(controller).to_not receive(:redirect_to).with("/")

            controller.handle_user_cache_key!
          end
        end
      end

    end
  end
end
