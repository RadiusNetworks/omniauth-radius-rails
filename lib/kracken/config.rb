module Kracken
  class Config
    attr_accessor :app_id, :app_secret
    attr_writer :provider_url, :user_class

    def provider_url
      @provider_url || "https://account.messageradius.com"
    end

    def user_class
      @user_class || User
    end
  end
end
