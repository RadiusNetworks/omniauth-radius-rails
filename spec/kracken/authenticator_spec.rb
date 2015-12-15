require 'spec_helper'

module Kracken
  RSpec.describe Authenticator do


    describe ".with_credentials" do
      let(:cred_auth) {
        object_double(
          CredentialAuthenticator.new,
          body: { 'uid' => 1 }
        )
      }

      it "creates a user using the user_class" do
        expect_any_instance_of(CredentialAuthenticator)
          .to receive(:fetch)
          .and_return(cred_auth)

        expect(Authenticator.user_with_credentials("melody@ponds.uk", "secret").class).to eq User
      end


      it "sets the user's uid" do
        expect_any_instance_of(CredentialAuthenticator)
          .to receive(:fetch)
          .and_return(cred_auth)

        expect(Authenticator.user_with_credentials("melody@ponds.uk", "secret").uid).to eq 1
      end
    end

    describe ".with_token" do
      let(:token_auth) {
        object_double(
          TokenAuthenticator.new,
          etag: "etag",
          body: { 'uid' => 1 }
        )
      }

      it "creates a user using the user_class" do
        expect_any_instance_of(TokenAuthenticator)
          .to receive(:fetch)
          .and_return(token_auth)

        expect(Authenticator.user_with_token("secret").class).to eq User
      end

      it "sets the user's uid" do
        expect_any_instance_of(TokenAuthenticator)
          .to receive(:fetch)
          .with("secret")
          .and_return(token_auth)

        expect(Authenticator.user_with_token("secret").uid).to eq 1
      end
    end
  end
end
