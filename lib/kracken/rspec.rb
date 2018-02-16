module Kracken
  module SpecHelper
    @@current_user = nil

    def self.current_user
      @@current_user
    end

    def self.current_user=(current_user)
      @@current_user = current_user
    end

    module Request
      def sign_in(user = nil)
        Kracken::SpecHelper.current_user = user
      end

      def token_authorize(user, token:)
        Kracken::Controllers::TokenAuthenticatable::cache_valid_auth(token, force: true) do
          { id: user.id, team_ids: user.team_ids }
        end
      end
    end

    module Controller
      def sign_in(user = nil)
        Kracken::SpecHelper.current_user = user
      end

      def sign_out(ignored = nil)
        Kracken::SpecHelper.current_user = nil
      end

      def current_user
        Kracken::SpecHelper.current_user
      end
    end

  end

end

# monkey patch current_user
module Kracken
  module Controllers
    module Authenticatable
      def current_user
        Kracken::SpecHelper.current_user
      end
    end
    module TokenAuthenticatable
      alias_method :__original_user__, :current_user
      def current_user
        Kracken::SpecHelper.current_user or
          (current_user_id && __original_user__)
      end

      alias_method :__original_auth__, :authenticate_user_with_token!
      def authenticate_user_with_token!
        if current_user
          @_auth_info = {
            id: current_user.id,
            team_ids: current_user.team_ids,
          }
        else
          __original_auth__
        end
      end
    end
  end
end

if defined? RSpec
  RSpec.configure do |c|
    c.include Kracken::SpecHelper::Controller, type: :controller
    c.include Kracken::SpecHelper::Request, type: :feature
    c.include Kracken::SpecHelper::Request, type: :system
    c.include Kracken::SpecHelper::Request, type: :kracken
    c.include Kracken::SpecHelper::Request, type: :request

    c.before do
      Kracken::Controllers::TokenAuthenticatable.clear_auth_cache
      Kracken::SpecHelper.current_user = nil
    end
  end
end
