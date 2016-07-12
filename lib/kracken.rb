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

module Kracken
  mattr_accessor :config
  @@config = Config.new

  def self.setup(&block)
    yield @@config
  end
end
