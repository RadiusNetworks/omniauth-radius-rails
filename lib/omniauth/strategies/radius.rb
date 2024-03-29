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
        access_token_url: "#{provider_url}/auth/radius/access_token"
      }

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
