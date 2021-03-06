# frozen_string_literal: true

require "kracken/env"
require "kracken/error"
require "kracken/engine"
require "kracken/config"
require "kracken/controllers/authenticatable"
require "kracken/controllers/token_authenticatable"
require "kracken/controllers/json_api_compatible"
require "kracken/token_authenticator"
require "kracken/credential_authenticator"
require "kracken/authenticator"
require "kracken/registration"
require "kracken/railtie" if defined?(Rails)
require "kracken/session_manager"

module Kracken
  mattr_accessor :config
  @@config = Config.new

  def self.setup
    yield @@config
  end
end
