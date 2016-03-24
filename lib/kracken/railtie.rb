require "kracken/json_api"

module Kracken
  # Railtie to hook into Rails.
  class Railtie < ::Rails::Railtie
    initializer "kracken.json_api.public_exceptions" do |app|
      app.middleware.insert_after ActionDispatch::DebugExceptions,
                                  ::Kracken::JsonApi::PublicExceptions
    end
  end
end
