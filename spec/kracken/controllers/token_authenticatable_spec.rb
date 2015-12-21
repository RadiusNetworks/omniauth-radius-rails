require "support/base_controller_double"
require "support/using_cache"

module Kracken
  class TokenAuthController < BaseControllerDouble
    include Kracken::Controllers::TokenAuthenticatable
    public :authenticate_user_with_token!
    # The module includes things as private so that they are not accidentally
    # exposed as controller routes. However, we really treat some of them as the
    # "public" API for the module:
    public :current_auth_info,
           :current_team_ids,
           :current_user,
           :current_user_id

    def authenticate_or_request_with_http_token(realm = nil)
      /\AToken token="(?<token>.*)"\z/ =~ request.env['HTTP_AUTHORIZATION']
      yield token if block_given?
    end
  end

  RSpec.describe Controllers::TokenAuthenticatable do
    describe "authenticating via a token", :using_cache do
      subject(:a_controller) { TokenAuthController.new }

      shared_examples "the authorization request headers" do |token_helper|
        let(:expected_token) { public_send token_helper }

        specify "are munged to include a provided parameterized token" do
          a_controller.request.env = {
            'HTTP_AUTHORIZATION' => 'Token token="header token"'
          }
          a_controller.params = { token: expected_token }

          expect {
            a_controller.authenticate_user_with_token!
          }.to change {
            a_controller.request.env
          }.from(
            'HTTP_AUTHORIZATION' => 'Token token="header token"'
          ).to(
            'HTTP_AUTHORIZATION' => "Token token=\"#{expected_token}\""
          )
        end

        specify "are not modified when no parameterized token provided" do
          a_controller.request.env = {
            'HTTP_AUTHORIZATION' => "Token token=\"#{expected_token}\""
          }

          expect {
            a_controller.authenticate_user_with_token!
          }.not_to change { a_controller.request.env }.from(
            'HTTP_AUTHORIZATION' => "Token token=\"#{expected_token}\""
          )
        end
      end

      context "on a cache hit" do
        let(:auth_info) {
          {
            id: :any_id,
            team_ids: [:some, :team, :ids],
          }
        }
        let(:cached_token) { "any token" }
        let(:cache_key) { "auth/token/any token" }

        before do
          a_controller.request.env = {
            'HTTP_AUTHORIZATION' => "Token token=\"#{cached_token}\""
          }

          Rails.cache.write cache_key, auth_info
          stub_const "Kracken::Authenticator", spy("Kracken::Authenticator")
        end

        include_examples "the authorization request headers", :cached_token

        it "uses the exising cache to bypass the authentication process" do
          a_controller.authenticate_user_with_token!
          expect(Authenticator).not_to have_received(:user_with_token)
        end

        it "returns the auth info" do
          expect(a_controller.authenticate_user_with_token!).to eq(
            id: :any_id,
            team_ids: [:some, :team, :ids],
          ).and be_frozen
        end

        it "exposes the auth info via the `current_` helpers", :aggregate_failures do
          expect {
            a_controller.authenticate_user_with_token!
          }.to(
            change { a_controller.current_auth_info }.from({}).to(auth_info)
            .and change { a_controller.current_user_id }.from(nil).to(:any_id)
            .and change { a_controller.current_team_ids }.from(nil).to(
              [:some, :team, :ids]
            )
          )

          expect(a_controller.current_auth_info).to be_frozen
          expect(a_controller.current_team_ids).to be_frozen
        end

        it "lazy loads the current user" do
          begin
            # Ensure we cannot lookup a user - doing so would raise an error
            org_user_class = Kracken.config.user_class
            user_class = double("AnyUserClass")
            Kracken.config.user_class = user_class

            # Action under test
            a_controller.authenticate_user_with_token!

            # Make sure we perform the lookup as expected now
            expect(user_class).to receive(:find).with(:any_id).and_return(:user)

            expect(a_controller.current_user).to be :user
          ensure
            Kracken.config.user_class = org_user_class
          end
        end
      end

      context "on a cache miss with an invalid token" do
        let(:invalid_token) { "any token" }

        before do
          a_controller.request.env = {
            'HTTP_AUTHORIZATION' => "Token token=\"#{invalid_token}\""
          }

          allow(Authenticator).to receive(:user_with_token).with(invalid_token)
                                                           .and_return(nil)
        end

        include_examples "the authorization request headers", :invalid_token

        it "follows the token authentication process" do
          a_controller.authenticate_user_with_token!
          expect(Authenticator).to have_received(:user_with_token)
            .with(invalid_token)
        end

        it "returns nil" do
          expect(a_controller.authenticate_user_with_token!).to be nil
        end

        it "doesn't cache invalid tokens" do
          expect {
            a_controller.authenticate_user_with_token!
          }.not_to change {
            Rails.cache.exist?("auth/token/#{invalid_token}")
          }.from false
        end
      end

      context "on a cache miss with a valid token" do
        let(:a_user) {
          instance_double(User, id: user_id, team_ids: some_team_ids)
        }
        let(:some_team_ids) { [:some, :team, :ids] }
        let(:user_id) { :any_id }
        let(:valid_token) { "any token" }

        before do
          a_controller.request.env = {
            'HTTP_AUTHORIZATION' => "Token token=\"#{valid_token}\""
          }

          allow(Authenticator).to receive(:user_with_token).with(valid_token)
                                                           .and_return(a_user)
        end

        include_examples "the authorization request headers", :valid_token

        it "follows the token authentication process" do
          a_controller.authenticate_user_with_token!
          expect(Authenticator).to have_received(:user_with_token)
            .with(valid_token)
        end

        it "returns the auth info in a frozen state" do
          expect(a_controller.authenticate_user_with_token!).to eq(
            id: :any_id,
            team_ids: [:some, :team, :ids],
          ).and be_frozen
        end

        it "exposes the auth info via the `current_` helpers", :aggregate_failures do
          expect {
            a_controller.authenticate_user_with_token!
          }.to(
            change { a_controller.current_auth_info }.from({}).to(
              id: :any_id,
              team_ids: [:some, :team, :ids],
            )
            .and change { a_controller.current_user_id }.from(nil).to(:any_id)
            .and change { a_controller.current_team_ids }.from(nil).to(
              [:some, :team, :ids]
            )
          )

          expect(a_controller.current_auth_info).to be_frozen
          expect(a_controller.current_team_ids).to be_frozen
        end

        it "sets the auth info as the cache value" do
          expect {
            a_controller.authenticate_user_with_token!
          }.to change { Rails.cache.read("auth/token/any token") }.from(nil).to(
            id: :any_id,
            team_ids: [:some, :team, :ids],
          )
        end

        it "sets the cache expiration to one minute by default" do
          expect(Rails.cache).to receive(:write).with(
            "auth/token/any token",
            anything,
            include(expires_in: 1.minute),
          )
          a_controller.authenticate_user_with_token!
        end

        it "eager loads the current user" do
          expect(Kracken.config.user_class).not_to receive(:find)
          a_controller.authenticate_user_with_token!
          expect(a_controller.current_user).to be a_user
        end

        # TODO: Delete this test after implementation is complete
        # This is only to ensure we maintain general backwards compatibility
        it "authenticates the current user via the token" do
          controller = TokenAuthController.new
          controller.request.env = {
            'HTTP_AUTHORIZATION' => 'Token token="any token"'
          }

          expect {
            controller.authenticate_user_with_token!
          }.to change { controller.current_user }.from(nil).to(a_user)
        end
      end
    end
  end
end
