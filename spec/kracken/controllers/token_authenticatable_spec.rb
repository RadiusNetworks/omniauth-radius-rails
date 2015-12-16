require "support/base_controller_double"

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
    describe "authenticating via a token" do
      context "on a cache hit" do
        it "munges the request headers to support parameterized tokens"
        it "leaves the request header unchange when with no parameterized token"
        it "uses the exising cache to bypass the authentication process"
        it "returns the auth info"
        it "exposes the auth info via the `current_` helpers"
        it "lazy loads the current user"
      end

      context "on a cache miss with an invalid token" do
        it "munges the request headers to support parameterized tokens"
        it "leaves the request header unchange when with no parameterized token"
        it "follows the token authentication process"
        it "returns nil"
        it "doesn't cache invalid tokens"
      end

      context "on a cache miss with a valid token" do
        before do
          allow(Authenticator).to receive(:user_with_token)
        end

        it "follows the token authentication process"
        it "returns the auth info"
        it "exposes the auth info via the `current_` helpers"
        it "sets the auth info as the cache value"
        it "sets the cache expiration to one minute by default"
        it "sets the cache expiration to the environment setting `KRACKEN_TOKEN_TTL` when available"
        it "eager loads the current user"

        it "munges the request headers to support parameterized tokens" do
          controller = TokenAuthController.new
          controller.request.env = {
            'HTTP_AUTHORIZATION' => 'Token token="header token"'
          }
          controller.params = { token: "param token" }

          expect {
            controller.authenticate_user_with_token!
          }.to change {
            controller.request.env
          }.from(
            'HTTP_AUTHORIZATION' => 'Token token="header token"'
          ).to(
            'HTTP_AUTHORIZATION' => 'Token token="param token"'
          )
        end

        it "leaves the request header unchange when with no parameterized token" do
          controller = TokenAuthController.new
          controller.request.env = {
            'HTTP_AUTHORIZATION' => 'Token token="any token"'
          }

          expect {
            controller.authenticate_user_with_token!
          }.not_to change { controller.request.env }.from(
            'HTTP_AUTHORIZATION' => 'Token token="any token"'
          )
        end

        it "authenticates the current user via the token" do
          a_user = instance_double(User)
          allow(Authenticator).to receive(:user_with_token).with("any token")
                                                           .and_return(a_user)
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
