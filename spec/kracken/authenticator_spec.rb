require 'spec_helper'

module Kracken
  describe Authenticator do


    describe ".with_credentials" do
      it "returns nil when nothing is found" do
        expect_any_instance_of(CredentialAuthenticator)
          .to receive(:fetch)
          .and_return(nil)

        expect(Authenticator.user_with_credentials("melody@ponds.uk", "secret")).to be_nil
      end

      it "creates a user using the user_class" do
        expect_any_instance_of(CredentialAuthenticator)
          .to receive(:fetch)
          .and_return({'uid' => 1})

        expect(Authenticator.user_with_credentials("melody@ponds.uk", "secret").class).to eq User
      end


      it "sets the user's uid" do
        expect_any_instance_of(CredentialAuthenticator)
          .to receive(:fetch)
          .and_return({'uid' => 1})

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
