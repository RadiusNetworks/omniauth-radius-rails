# frozen_string_literal: true

module Kracken
  class SessionsController < ActionController::Base
    protect_from_forgery with: :exception

    def create
      @user = user_class.find_or_create_from_auth_hash(auth_hash)
      session[:user_id] = @user.id
      session[:user_cache_key] = SESSION_REDIS.get(user_session_key(@user.id))
      session[:token_expires_at] = Time.zone.at(auth_hash[:credentials][:expires_at])
      redirect_to return_to_path
    end

    def destroy
      reset_session
      redirect_to "#{provider_url}/users/sign_out#{signout_redirect_query}"
    end

    def failure
      render text: "Sorry, but you didn't allow access to our app!"
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

    def user_session_key(id)
      "rnsession:#{id}"
    end
  end
end
