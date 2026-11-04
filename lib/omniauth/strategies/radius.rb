# frozen_string_literal: true

require 'omniauth-oauth2'

begin
  require 'dotenv'
  Dotenv.load
rescue LoadError => e
  raise unless e.message.include?('dotenv')
end

module OmniAuth
  module Strategies
    class Radius < OmniAuth::Strategies::OAuth2

      def self.provider_url
        Kracken::PROVIDER_URL
      end

      option :client_options, {
        site: provider_url,
        authorize_url: "#{provider_url}/auth/radius/authorize",
        # `access_token_url` is not an oauth2 option -- the key is `token_url`
        # -- so this previously fell through to oauth2's default of
        # `<site>/oauth/token`. That default is what the account server
        # actually serves (it only routes GET, not POST, for
        # `/auth/radius/access_token`), so name it explicitly rather than
        # leave a key that looks meaningful and is not.
        token_url: "#{provider_url}/oauth/token",
        # oauth2 2.0 changed the default from `:request_body` to `:basic_auth`.
        # The account server reads `client_id` / `client_secret` from params
        # only, so keep sending them in the body. Drop this once the provider
        # accepts HTTP Basic client credentials.
        auth_scheme: :request_body,
      }

      # PKCE (RFC 7636): send an S256 code_challenge on authorize and the
      # matching code_verifier on the token request. omniauth-oauth2 >= 1.7
      # generates the verifier per request and keeps it in the session.
      option :pkce, true

      uid { raw_info['id'] }

      info do
        raw_info["info"].slice(
          "first_name",
          "last_name",
          "email",
          "uid",
          "confirmed",
          "teams",
          "organizations",
          "organization_roles",
          "team_memberships",
          "services",
          "service_roles",
          "linked_accounts",
          "admin",
          "subscription_level",
        )
      end

      extra do
        {
          raw_info: raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get("/auth/radius/user.json?oauth_token=#{access_token.token}").parsed
      end
    end
  end
end
