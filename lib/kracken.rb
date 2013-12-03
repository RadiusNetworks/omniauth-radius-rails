
require "kracken/env"
require "kracken/engine"
require "kracken/config"
require "kracken/controllers/authenticatable"

module Kracken
  mattr_accessor :config
  @@config = Config.new

  def self.setup(&block)
    yield @@config
  end
end
