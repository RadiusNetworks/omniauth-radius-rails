# frozen_string_literal: true

module Kracken
  class SessionsController < ActionController::Base # rubocop:disable Rails/ApplicationController
    protect_from_forgery with: :exception

    def create # rubocop:disable Metrics/AbcSize
      @user = user_class.find_or_create_from_auth_hash(auth_hash)
      session[:user_id] = @user.id
      session[:user_uid] = @user.uid
      session[:is_admin] = @user.admin
      session[:user_cache_key] = Kracken::SessionManager.get(@user.uid)
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
      return "/" unless request.env['omniauth.origin'].starts_with?('/')

      request.env['omniauth.origin']
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
