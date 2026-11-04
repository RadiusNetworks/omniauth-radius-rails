# frozen_string_literal: true

require 'omniauth/strategies/radius'

# Registers the railtie that points OmniAuth's request validation at Rails'
# `authenticity_token`. This is a transitive dependency of this gem rather
# than an entry in the host app's Gemfile, so `Bundler.require` will not load
# it for them -- without this require the request phase silently falls back to
# OmniAuth's own rack-protection check, which does not understand Rails'
# token.
require 'omniauth/rails_csrf_protection'

module Kracken
  class Engine < ::Rails::Engine
    isolate_namespace Kracken

    initializer "kracken.omniauth" do |_app|
      Rails.application.config.middleware.use OmniAuth::Builder do
        provider :radius, Kracken.config.app_id, Kracken.config.app_secret
      end
    end

    #initializer 'kracken.action_controller' do |app|
    #  ActiveSupport.on_load :action_controller do
    #    helper Kracken::ApplicationHelper
    #  end
    #end

  end
end
