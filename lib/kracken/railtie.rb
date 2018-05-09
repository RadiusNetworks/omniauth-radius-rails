require "kracken/json_api"

module Kracken
  # Railtie to hook into Rails.
  class Railtie < ::Rails::Railtie
    initializer "kracken.json_api.public_exceptions" do |app|
      app.middleware.insert_after ActionDispatch::DebugExceptions,
                                  ::Kracken::JsonApi::PublicExceptions
    end

    config.before_initialize do |app|
      app.config.filter_parameters += %i[
        code
        email
        linked_accounts
        raw_info
        redirect_to
        redirect_uri
        state
        token
      ]
      app.config.filter_redirect += [
        "auth/radius",
        "auth/token",
      ]
    end

    # Allow apps to configure the provider in initializers
    config.after_initialize do |app|
      app.config.filter_redirect << URI(Kracken.config.provider_url).host
    end
  end
end
