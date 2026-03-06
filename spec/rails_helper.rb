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
