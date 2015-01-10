module Kracken
  module Controllers
    module JsonApiCompatible
      def self.included(klass)
        klass.instance_exec do
          before_action :munge_chained_param_ids!

          unless Rails.env.development?
            rescue_from StandardError do |error|
              render_json_error 500, error
            end

            rescue_from  ActionController::RoutingError do |error|
              render_json_error 404, error
            end

            rescue_from ActiveRecord::RecordNotFound do |error|
              render_json_error 404, error
            end
          end

        end
      end

      private

      def munge_chained_param_ids!
        return unless params[:id]
        params[:id] = params[:id].split(/,\s*/)
      end

      def render_json_error(status, error)
        body = {error: {message: error.message, backtrace: error.backtrace}}
        render status: status, json: body
      end

      # Customize the `authenticate_or_request_with_http_token` process:
      # http://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token/ControllerMethods.html#method-i-request_http_token_authentication
      def request_http_token_authentication(realm = 'Application')
        # Modified from https://github.com/rails/rails/blob/60d0aec7/actionpack/lib/action_controller/metal/http_authentication.rb#L490-L499
        headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
        render json: { error: 'HTTP Token: Access denied.' }, status: :unauthorized
      end
    end
  end
end

