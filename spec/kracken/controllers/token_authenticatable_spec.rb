# frozen_string_literal: true

require "rails_helper"
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

    def authenticate_or_request_with_http_token(_realm = nil)
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
            ActiveSupport::Deprecation.silence do
              a_controller.authenticate_user_with_token!
            end
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
        let(:cache_key) { "any token" }

        before do
          a_controller.request.env = {
            'HTTP_AUTHORIZATION' => "Token token=\"#{cached_token}\""
          }

          Controllers::TokenAuthenticatable.store_valid_auth cached_token do
            auth_info
          end
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

        it "handles already frozen auth hashes" do
          # This seems to happen on the 2nd cache read - despite the hash being
          # frozen when put into the cache the first cache read will not be
          # frozen. However, subsequent reads seem to be froze - this may be
          # Rails version dependent. Regardless, we need to be aware of it.

          # Initial cache request
          expect(a_controller.authenticate_user_with_token!).to eq(
            id: :any_id,
            team_ids: [:some, :team, :ids],
          ).and be_frozen

          # Secondary cache request
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
          # Action under test
          a_controller.authenticate_user_with_token!

          # Make sure we perform the lookup as expected now
          expect(::User).to receive(:find).with(:any_id).and_return(:user)

          expect(a_controller.current_user).to be :user
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
            Controllers::TokenAuthenticatable.cache.exist?(
              Controllers::TokenAuthenticatable.auth_cache_key(invalid_token)
            )
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

        it "sets the auth info, along with a nonce, and HMAC as the cache value" do
          expect {
            a_controller.authenticate_user_with_token!
          }.to change {
            Controllers::TokenAuthenticatable.cache.read(
              Controllers::TokenAuthenticatable.auth_cache_key("any token")
            )
          }.from(nil).to(
            [
              {
                id: :any_id,
                team_ids: [:some, :team, :ids],
              },
              be_a(String).and(satisfy { |s| s.size == 64 }),
              be_a(String).and(satisfy { |s| s.size == 32 }),
            ]
          )
        end

        it "sets the cache expiration to one minute by default" do
          expect(Controllers::TokenAuthenticatable.cache).to receive(:write).with(
            Controllers::TokenAuthenticatable.auth_cache_key("any token"),
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

        it "treats an HMAC verification failure as a miss" do
          initial_salt = "salt" * 16
          initial_hmac = "hmac" * 8
          cache_key = Controllers::TokenAuthenticatable.auth_cache_key(
            "any token"
          )
          Controllers::TokenAuthenticatable.cache.write(
            cache_key,
            [
              {
                id: :any_id,
                team_ids: [:some, :team, :ids],
              },
              initial_salt,
              initial_hmac,
            ],
          )

          expect {
            a_controller.authenticate_user_with_token!
          }.to change {
            Controllers::TokenAuthenticatable.cache.read(cache_key)
          }.from(
            [
              {
                id: :any_id,
                team_ids: [:some, :team, :ids],
              },
              initial_salt,
              initial_hmac,
            ],
          ).to(
            [
              {
                id: :any_id,
                team_ids: [:some, :team, :ids],
              },
              be_a(String).and(satisfy { |s| s.size == 64 && s != initial_salt}),
              be_a(String).and(satisfy { |s| s.size == 32 && s != initial_hmac}),
            ]
          )
          expect(Authenticator).to have_received(:user_with_token)
            .with(valid_token)
        end
      end
    end
  end
end
