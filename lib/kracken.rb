
require "kracken/env"
require "kracken/engine"
require "kracken/config"
require "kracken/controllers/authenticatable"
require "kracken/controllers/token_authenticatable"
require "kracken/controllers/json_api_compatible"
require "kracken/updater"
require "kracken/login"

module Kracken
  mattr_accessor :config
  @@config = Config.new

  def self.setup(&block)
    yield @@config
  end
end
