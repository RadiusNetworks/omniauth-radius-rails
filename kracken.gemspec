$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "kracken/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "kracken"
  s.version     = Kracken::VERSION
  s.authors     = ["Christopher Sexton"]
  s.email       = ["chris@radiusnetworks.com"]
  s.homepage    = "http://www.radiusnetworks.com"
  s.summary     = "Rails engine for use with Kracken"
  s.description = "Rails engine for use with the Radius Networks Account Server."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 4.0.0"
  s.add_dependency "omniauth-radius"

  s.add_development_dependency 'rspec-rails'
end
