# frozen_string_literal: true

module Kracken
  class SessionsController < ActionController::Base # rubocop:disable Rails/ApplicationController
    protect_from_forgery with: :exception

    # GET /sign_in
    #
    # OmniAuth 2 only accepts the request phase over POST, carrying Rails'
    # authenticity token, so an unauthenticated request can no longer simply
    # be redirected to `/auth/radius`. This renders a form that posts there
    # and submits it on load, leaving a working button for anyone whose
    # browser does not run the script (or whose CSP blocks it).
    def new
      @sign_in_action = sign_in_action
      render layout: false
    end

    def create # rubocop:disable Metrics/AbcSize
      @user = user_class.find_or_create_from_auth_hash(auth_hash)
      session[:user_id] = @user.id
      session[:user_uid] = @user.uid
      session[:is_admin] = @user.admin
      session[:user_cache_key] = Kracken::SessionManager.get(@user.uid)
      session[:token_expires_at] = Time.zone.at(auth_hash[:credentials][:expires_at])

      redirect_to return_to_path
    end

    # DELETE /sign_out
    #
    # Ends this app's session, then hands off to the account server with a
    # signed token so it can end its session too. Without a signed in user
    # there is nothing to sign, so the account server asks them to confirm.
    def destroy
      uid = session[:user_uid]
      reset_session

      if uid.present?
        redirect_to Kracken::LogoutToken.url(uid: uid, redirect_to: signout_redirect_url), allow_other_host: true
      else
        redirect_to confirm_sign_out_url, allow_other_host: true
      end
    end

    def failure
      render plain: "Sorry, we couldn't sign you in. Please try again.", status: :unauthorized
    end

  protected

    def sign_in_action
      origin = safe_origin
      return '/auth/radius' unless origin

      "/auth/radius?origin=#{CGI.escape(origin)}"
    end

    # `origin` is attacker-controllable, so only reflect a plain local path
    # into the form. `return_to_path` checks this again on the way back; this
    # keeps a hostile value out of the rendered page in the first place.
    def safe_origin
      origin = params[:origin]
      return unless origin.is_a?(String)
      return unless origin.match?(%r{\A/(?![/\\])})

      origin
    end

    # A stale token (an old tab, an expired session) fails the CSRF check the
    # same way a forged request does, so we can't tell them apart. Rather than
    # an error page, leave this session alone and let the account server ask
    # the user to confirm. Signing out there invalidates the session cache key,
    # which signs them out here on their next request.
    def handle_unverified_request
      return super unless action_name == "destroy"

      redirect_to confirm_sign_out_url, allow_other_host: true
    end

    def return_to_path
      origin = request.env['omniauth.origin']
      return "/" unless origin&.start_with?('/')
      return "/" if URI.parse(origin).host
      origin
    rescue URI::InvalidURIError
      "/"
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

    def confirm_sign_out_url
      "#{provider_url}/users/sign_out?redirect_to=#{CGI.escape(signout_redirect_url)}"
    end

    def signout_redirect_url
      current_root = URI(request.url)
      current_root.path = ''
      current_root.query = nil
      current_root.to_s
    end
  end
end
