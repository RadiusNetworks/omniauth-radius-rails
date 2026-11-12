# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'active_support/all'
require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'kracken'

# Minimal Rails app for testing the engine
unless defined?(TestApp)
  class TestApp < Rails::Application
    config.eager_load = false
    config.secret_key_base = 'test-secret-key-base'
    config.hosts.clear

    # The app root is the gem root, so Rails would otherwise load the
    # *engine's* `config/routes.rb` as the application's routes file too,
    # drawing it twice. That was invisible while the file had no named
    # routes; it raises "Invalid route name, already in use" as soon as one
    # is added. The app's routes come from `routes.append` below instead.
    config.paths["config/routes.rb"] = []
  end
  # Mount the engine so request specs can drive the real middleware stack
  # (the OmniAuth request phase in particular) rather than only controllers.
  # `routes.append` is evaluated by the routes reloader as part of the single
  # draw, so the engine's own routes file is not loaded a second time.
  # The engine builds the OmniAuth middleware during initialization, capturing
  # these values, so they have to be set before `initialize!` for the request
  # phase to get past its own `missing_client_id` guard.
  Kracken.setup do |config|
    config.app_id = 'test-app-id'
    config.app_secret = 'test-app-secret'
  end

  TestApp.routes.append do
    mount Kracken::Engine => "/auth"
  end

  TestApp.initialize!
end

require 'spec_helper'
require 'rspec/rails'
require 'webmock/rspec'

Dir["#{__dir__}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.filter_rails_from_backtrace!
  config.infer_base_class_for_anonymous_controllers = false
end
