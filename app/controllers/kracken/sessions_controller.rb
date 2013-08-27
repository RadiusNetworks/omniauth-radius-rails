module Kracken
  class SessionsController < ApplicationController
    def create
      @user = user_class.find_or_create_from_auth_hash(auth_hash)
      current_user = @user
      session[:user_id] = @user.id
      redirect_to request.env['omniauth.origin'] || root_path
    end

    def destroy
      reset_session
      redirect_to "#{provider_url}/users/sign_out"
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

    def user_class
      Kracken.config.user_class
    end

    def provider_url
      Kracken.config.provider_url
    end
  end
end
