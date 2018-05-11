
# frozen_string_literal: true

# If this gem is loaded via bundler before the rails initializer we need to
# manually pull in dotenv or the .env file will not be read. Ugly hack, but
# since the omniauth strategy sets the options when the class is defined we
# need to do something to shim this in.
begin
  require 'dotenv'
  Dotenv.load
rescue LoadError
end

module Kracken
  PROVIDER_URL = ENV['RADIUS_OAUTH_PROVIDER_URL'] || "https://account.radiusnetworks.com"
end
