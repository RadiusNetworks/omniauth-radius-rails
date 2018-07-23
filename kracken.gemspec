# frozen_string_literal: true

$:.push File.expand_path('../lib', __FILE__)

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

  s.add_dependency 'rails', [">= 4.0", "< 6.0"]
  s.add_dependency 'omniauth', '~> 1.0'
  s.add_dependency 'faraday', '~> 0.8'
  s.add_dependency 'omniauth-oauth2', '~> 1.1'

  s.add_development_dependency 'rspec-rails', '~> 3.5'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-nav'
  s.add_development_dependency 'webmock'
end
