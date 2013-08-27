require "kracken/engine"
require "kracken/controllers/authenticatable"

module Kracken
  Config = Struct.new( :app_id, :app_secret, :provider_url) do
    def url
      provider_url || "https://account.messageradius.com"
    end
  end

  mattr_accessor :config
  @@config = Config.new

  def self.setup(&block)
    yield @@config
  end
end
