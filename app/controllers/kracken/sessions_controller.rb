module Kracken
  class SessionsController < ApplicationController
    def create
      @user = user_class.find_or_create_from_auth_hash(auth_hash)
      current_user = @user
      session[:user_id] = @user.id
      redirect_to return_to_path
    end

    def destroy
      reset_session
      redirect_to "#{provider_url}/users/sign_out#{signout_redirect_query}"
    end

    def failure
      render text: "Sorry, but you didn't allow access to our app!"
    end

    def index
      authenticate_user!
    end

    protected

    def return_to_path
      request.env['omniauth.origin'] || "/"
    end

    def auth_hash
      request.env['omniauth.auth']
    end

    def user_class
      Kracken.config.user_class
    end

    def provider_url
      Kracken.config.provider_url
    end

    def signout_redirect_query
      current_root = URI(request.url)
      current_root.path = ''
      "?redirect_to=#{CGI.escape(current_root.to_s)}"
    end
  end
end
