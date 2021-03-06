# frozen_string_literal: true

module Kracken
  module Controllers
    module Authenticatable

      def self.included(base)
        base.instance_exec do
          before_action :handle_user_cache_key!
          before_action :authenticate_user!
          helper_method :sign_out_path, :sign_up_path, :sign_in_path,
                        :current_user, :user_signed_in?
        end
      end

      def sign_out_path
        kracken.sign_out_path
      end

      def sign_up_path(query_params = {})
        uri = URI("#{Kracken.config.provider_url}/users/sign_up")
        uri.query = query_params.to_query unless query_params.empty?
        uri.to_s
      end

      def sign_in_path(return_to=nil)
        # Setup the return_to path for after authentication
        origin_path = ''
        origin_path = "?origin=#{CGI.escape return_to}" if return_to

        '/auth/radius' + origin_path
      end

      def authenticate_user
        check_token_expiry!
        user_signed_in?
      end

      def authenticate_user!
        return if authenticate_user

        if request.format == :json
          render json: {error: '401 Unauthorized'}, status: :unauthorized
        elsif request.format == :js
          head :unauthorized
        else
          redirect_to_sign_in
        end
      end

      def check_token_expiry!
        if session[:token_expires_at].nil? || session[:token_expires_at] < Time.zone.now
          delete_session_data
        end
      end

      # We needed a way to update the user information on kracken and
      # automatically update all the client apps. Instead of pushing changes
      # to all the apps we added a cookie that will act as an indicator that
      # the user is stale and they need to refresh them.
      #
      # The refresh is accomplished by redirecting to the normal oauth flow
      # which will simply redirect the back if they are already signed in (or
      # ask for a user/pass if they are not).
      #
      # This method will:
      #
      #  - Check for the presence of a user cache key in Redis
      #  - Compare it to the `user_cache_key` in the session
      #  - If they don't match, redirect them to the oauth provider and
      #    delete the session
      #
      def handle_user_cache_key!
        return unless session_present?
        return if session_and_redis_match?

        delete_session_data
        redirect_to_sign_in
      end

      def current_user=(u)
        @current_user = u
      end

      def current_user
        @current_user ||= fetch_current_user
      end

      def fetch_current_user
        begin
          self.current_user = user_class.find(session[:user_id]) if session[:user_id]
        rescue => e
          # This was `rescue Mongoid::Errors::DocumentNotFound` but that
          # introduced mongo as an dep. So for now just throw the error. If
          # someone gets a 500 it's because the user_id in their session did
          # not exist.

          STDERR.puts "Kracken: Authentication Error: #{e}"
          Rails.logger.error e if defined? Rails

          nil
        end
      end

      def user_signed_in?
        if current_user
          true
        else
          false
        end
      end

      private

      def session_present?
        session[:user_uid] && session[:user_cache_key]
      end

      def session_and_redis_match?
        Kracken::SessionManager.get(session[:user_uid]) == session[:user_cache_key]
      end

      def delete_session_data
        # Sign out current user
        session.delete :user_id

        # Clear that user's cache data
        session.delete :user_uid
        session.delete :user_cache_key
      end

      def user_class
        Kracken.config.user_class
      end

      def redirect_to_sign_in
        if request.fullpath
          redirect_to sign_in_path(request.fullpath)
        else
          redirect_to root_url
        end
      end

    end
  end
end
