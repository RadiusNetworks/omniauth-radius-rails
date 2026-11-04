# frozen_string_literal: true

$:.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'kracken/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'kracken'
  s.version     = Kracken::VERSION
  s.authors     = ['Christopher Sexton']
  s.email       = ['chris@radiusnetworks.com']
  s.homepage    = 'http://www.radiusnetworks.com'
  s.summary     = 'Rails engine that consumes the Kracken'
  s.description = 'Rails engine for use with the Radius Networks Account Server.'

  s.files = Dir['{app,exe,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  s.bindir      = "exe"
  s.executables = s.files.grep(%r{^exe/}) { |f| File.basename(f) }

  s.add_dependency 'faraday', '~> 2.0'
  s.add_dependency 'hashie', '>= 3.4.6'
  s.add_dependency 'oauth2', '~> 2.0'
  s.add_dependency 'omniauth', '~> 2.0'
  s.add_dependency 'omniauth-oauth2', '~> 1.10'
  # OmniAuth 2 validates the request phase, but its built-in check uses
  # rack-protection's token rather than Rails'. This wires it to Rails'
  # `authenticity_token` and restricts the request phase to POST.
  s.add_dependency 'omniauth-rails_csrf_protection', '~> 2.0'
  s.required_ruby_version = '>= 3.1.7'

  s.add_dependency 'rails', [">= 7.1", "< 9"]
  s.add_dependency 'redis'

  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rspec-rails', '>= 6.1'
  s.add_development_dependency 'webmock', '~> 3.8'
  s.metadata['rubygems_mfa_required'] = 'true'
end
