module Kracken
  class Config
    attr_accessor :app_id, :app_secret
    attr_writer :provider_url, :user_class

    def initialize
      @user_class = nil
    end

    def provider_url
      @provider_url ||= PROVIDER_URL
    end

    def user_class
      @user_class || ::User
    end
  end
end
