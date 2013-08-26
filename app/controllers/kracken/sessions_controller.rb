module Kracken
  class SessionsController < ApplicationController
    def create
      @user = User.find_or_create_from_auth_hash(auth_hash)
      current_user = @user
      session[:user_id] = @user.id
      redirect_to request.env['omniauth.origin'] || root_path
    end

    def destroy
      reset_session
      redirect_to "#{Rails.application.config.oauth_provider_url}/users/sign_out"
    end

    def failure
    end

    def index
      authenticate_user!
      render text: 'hi'
    end

    protected

    def auth_hash
      request.env['omniauth.auth']
    end
  end
end
