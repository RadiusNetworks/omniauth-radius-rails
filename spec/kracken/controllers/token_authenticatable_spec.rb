require "support/base_controller_double"

module Kracken
  class TokenAuthController < BaseControllerDouble
    include Kracken::Controllers::TokenAuthenticatable
    public :authenticate_user_with_token!
    public :current_user

    def authenticate_or_request_with_http_token(realm = nil)
      /\AToken token="(?<token>.*)"\z/ =~ request.env['HTTP_AUTHORIZATION']
      yield token if block_given?
    end
  end

  RSpec.describe Controllers::TokenAuthenticatable do
    describe "authenticating via a token" do
      context "on a cache miss with a valid token" do
        before do
          allow(Authenticator).to receive(:user_with_token)
        end

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
