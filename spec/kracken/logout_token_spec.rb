# frozen_string_literal: true

require 'rails_helper'

module Kracken
  RSpec.describe LogoutToken do
    around do |example|
      original = [Kracken.config.app_id, Kracken.config.app_secret]
      Kracken.config.app_id = "captain"
      Kracken.config.app_secret = "shh"
      begin
        example.run
      ensure
        Kracken.config.app_id, Kracken.config.app_secret = original
      end
    end

    it "signs the documented payload with the app secret" do
      expect(
        LogoutToken.signature("shh", client_id: "captain", uid: "42", timestamp: "1800000000",
                                     redirect_to: "https://captain.test"),
      ).to eq OpenSSL::HMAC.hexdigest("SHA256", "shh", "logout|captain|42|1800000000|https://captain.test")
    end

    it "builds the account server's client_sign_out URL" do
      url = URI(LogoutToken.url(uid: 42, redirect_to: "https://captain.test", now: Time.at(1_800_000_000).utc))
      params = Rack::Utils.parse_query(url.query)

      expect(url.path).to eq "/users/client_sign_out"
      expect(params).to eq(
        "client_id" => "captain",
        "uid" => "42",
        "ts" => "1800000000",
        "redirect_to" => "https://captain.test",
        "sig" => LogoutToken.signature("shh", client_id: "captain", uid: "42", timestamp: "1800000000",
                                              redirect_to: "https://captain.test"),
      )
    end

    it "changes the signature when any signed field changes" do
      base = { client_id: "captain", uid: "42", timestamp: "1800000000", redirect_to: "https://captain.test" }
      signatures = [
        base,
        base.merge(uid: "43"),
        base.merge(timestamp: "1800000001"),
        base.merge(redirect_to: "https://evil.test"),
        base.merge(client_id: "other"),
      ].map { |fields| LogoutToken.signature("shh", **fields) }

      expect(signatures.uniq.size).to eq 5
    end
  end
end
