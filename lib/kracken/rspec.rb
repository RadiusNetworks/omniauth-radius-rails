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
  end
end

if defined? RSpec
  RSpec.configure do |c|
    c.include Kracken::SpecHelper::Controller, type: :controller, example_group: {
      file_path: c.escaped_path(%w[spec controllers])
    }

    c.include Kracken::SpecHelper::Request, type: :request, example_group: {
      file_path: c.escaped_path(%w[spec (requests|integration|api)])
    }

    c.before( type: :controller) do
        Kracken::SpecHelper.current_user = nil
    end
    c.before( type: :request) do
        Kracken::SpecHelper.current_user = nil
    end
  end
end
