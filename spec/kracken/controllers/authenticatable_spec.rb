require 'spec_helper'


module Kracken
  module Controllers

    class ControllerDouble < BaseControllerDouble
      include Kracken::Controllers::Authenticatable
    end

    describe Authenticatable do
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
        it "#authenticate! redirects to root_url" do
          allow(controller).to receive(:request).and_return(double(format: nil, fullpath: nil))
          allow(controller).to receive(:redirect_to)

          controller.authenticate_user!

          expect(controller).to have_received(:redirect_to).with("/")
        end

        it "#user_signed_in? is false" do
          expect(controller.user_signed_in?).to be_falsey
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
          controller.session[:token_expires_at] = 5.minutes.ago
          controller.authenticate_user!
          expect(controller).to have_received(:redirect_to)
        end

        it "authenticates user when token has not expired" do
          allow(controller).to receive(:request).and_return(double(format: nil, fullpath: nil))
          allow(controller).to receive(:redirect_to)
          controller.session[:token_expires_at] = Time.now + 5.minutes
          controller.authenticate_user!
          expect(controller).to_not have_received(:redirect_to)
        end

        context "user cache cookie" do
          it "nothing if the cache cookie does not exist" do
            allow(controller).to receive(:request).and_return(double(format: nil, fullpath: nil))
            allow(controller).to receive(:redirect_to)
            controller.session[:user_cache_key] = "123"

            controller.handle_user_cache_cookie!

            expect(controller).to_not have_received(:redirect_to)
          end

          it "signs the current user out when the cache cookie is 'none'" do
            allow(controller).to receive(:request).and_return(double(format: nil, fullpath: nil))
            allow(controller).to receive(:redirect_to)
            controller.cookies[:_radius_user_cache_key] = "123"
            controller.session[:user_cache_key] = "123"

            controller.handle_user_cache_cookie!

            expect(controller).to_not have_received(:redirect_to)
          end

          it "redirects when the cache cookie is different than the session" do
            allow(controller).to receive(:request).and_return(double(format: nil, fullpath: nil))
            allow(controller).to receive(:cookies).and_return({_radius_user_cache_key: "123"})
            allow(controller).to receive(:redirect_to)
            controller.handle_user_cache_cookie!

            expect(controller).to have_received(:redirect_to).with("/")
          end

          it "does not redirect when the cache cookie matches the session" do
            controller.session = spy
            allow(controller).to receive(:redirect_to)
            controller.cookies[:_radius_user_cache_key] = "none"

            controller.handle_user_cache_cookie!

            expect(controller).to_not have_received(:redirect_to)
            expect(controller.session).to have_received(:delete).with(:user_id)
            expect(controller.session).to have_received(:delete).with(:user_cache_key)
          end
        end
      end

    end
  end
end
