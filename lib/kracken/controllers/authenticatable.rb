module Kracken
  module Controllers
    module Authenticatable

      def self.included(base)
        base.send :helper_method, :sign_out_path
        base.send :helper_method, :sign_up_path
        base.send :helper_method, :sign_in_path
        base.send :helper_method, :current_user
        base.send :helper_method, :user_signed_in?
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

      def current_user=(u)
        @current_user = u
      end

      def current_user
        return @current_user if @current_user
        fetch_current_user
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

      def user_class
        Kracken.config.user_class
      end

    end

  end
end
