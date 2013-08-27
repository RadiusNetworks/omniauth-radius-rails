module Kracken
  module Controllers
    module Authenticatable

      def self.included(base)
        base.send :helper_method, :sign_out_path
        base.send :helper_method, :sign_up_path
        base.send :helper_method, :sign_in_path
        base.send :helper_method, :current_user
        base.send :helper_method, :user_signed_in?
        base.send :helper_method, :is_admin
        base.send :helper_method, :current_user
      end

      def sign_out_path
        kracken.sign_out_path
      end

      def sign_up_path
        "#{Kracken.config.provider_url}/users/sign_up"
      end

      def sign_in_path(return_to=nil)
        # Setup the return_to path for after authentication
        origin_path = ''
        origin_path = "?origin=#{CGI.escape return_to}" if return_to

        '/auth/radius' + origin_path
      end

      def authenticate_user
        user_signed_in?
      end

      def authenticate_user!
        unless user_signed_in?
          if request.format == :json
            render json: {error: '401 Unauthorized'}, status: :unauthorized
          else
            if request.fullpath
              redirect_to sign_in_path(request.fullpath)
            else
              redirect_to root_url
            end
          end
        end
      end

      def authorize_admin!
        unless user_signed_in? && current_user.admin?
          if request.format == :json
            render json: {error: '403 Forbidden'}, status: :forbidden
          else
            redirect_to root_url
          end
        end
      end

      def current_user=(u)
        @current_user = u
      end

      def current_user
        return @current_user if @current_user
        begin
          self.current_user = user_class.find(session[:user_id]) if session[:user_id]
          # This was `rescue Mongoid::Errors::DocumentNotFound` but that
          # introduced mongo as an dep. So for now just throw the error. If
          # someone gets a 500 it's because the user_id in their session did
          # not exist.
        end
      end

      def user_signed_in?
        if current_user
          true
        else
          false
        end
      end

      def is_admin
        current_user && current_user.is_admin
      end

      private

      def user_class
        Kracken.config.user_class
      end

    end

  end
end
