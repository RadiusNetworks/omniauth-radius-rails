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
      shared_examples "the authorization request headers" do |token_helper|
        let(:expected_token) { public_send token_helper }

        specify "are munged to include a provided parameterized token" do
          controller = TokenAuthController.new
          controller.request.env = {
            'HTTP_AUTHORIZATION' => 'Token token="header token"'
          }
          controller.params = { token: expected_token }

          expect {
            controller.authenticate_user_with_token!
          }.to change {
            controller.request.env
          }.from(
            'HTTP_AUTHORIZATION' => 'Token token="header token"'
          ).to(
            'HTTP_AUTHORIZATION' => "Token token=\"#{expected_token}\""
          )
        end

        specify "are not modified when no parameterized token provided" do
          controller = TokenAuthController.new
          controller.request.env = {
            'HTTP_AUTHORIZATION' => "Token token=\"#{expected_token}\""
          }

          expect {
            controller.authenticate_user_with_token!
          }.not_to change { controller.request.env }.from(
            'HTTP_AUTHORIZATION' => "Token token=\"#{expected_token}\""
          )
        end
      end

      context "on a cache hit" do
        let(:cached_token) { "any token" }
        let(:cache_key) { "auth/token/any token" }

        before do
          Rails.cache.write(cache_key, "auth info")
        end

        include_examples "the authorization request headers", :cached_token

        it "uses the exising cache to bypass the authentication process"
        it "returns the auth info"
        it "exposes the auth info via the `current_` helpers"
        it "lazy loads the current user"
      end

      context "on a cache miss with an invalid token" do
        let(:invalid_token) { "any token" }

        before do
          allow(Authenticator).to receive(:user_with_token).with(invalid_token)
                                                           .and_return(nil)
        end

        include_examples "the authorization request headers", :invalid_token

        it "follows the token authentication process"
        it "returns nil"
        it "doesn't cache invalid tokens"
      end

      context "on a cache miss with a valid token" do
        let(:a_user) {
          instance_double(User, id: user_id, team_ids: some_team_ids)
        }
        let(:some_team_ids) { [:some, :team, :ids] }
        let(:user_id) { :any_id }
        let(:valid_token) { "any token" }

        before do
          allow(Authenticator).to receive(:user_with_token).with(valid_token)
                                                           .and_return(a_user)
        end

        include_examples "the authorization request headers", :valid_token

        it "follows the token authentication process"
        it "returns the auth info"
        it "exposes the auth info via the `current_` helpers"
        it "sets the auth info as the cache value"
        it "sets the cache expiration to one minute by default"
        it "sets the cache expiration to the environment setting `KRACKEN_TOKEN_TTL` when available"
        it "eager loads the current user"

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
