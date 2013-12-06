module Kracken
  class SyncController < ApplicationController
    def user
      token = user_class.get_auth_token_for_uid params[:uid]
      updater = Kracken::Updater.new token
      updater.refresh_with_oauth!
      render text: "Always take a banana to a party"
    end

    private

    def user_class
      Kracken.config.user_class
    end
  end
end
