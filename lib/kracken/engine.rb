# frozen_string_literal: true

require 'omniauth/strategies/radius'

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
