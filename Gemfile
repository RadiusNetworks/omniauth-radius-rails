# frozen_string_literal: true

source "https://rubygems.org"

# Declare your gem's dependencies in kracken.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use debugger
# gem 'debugger'

rails_dependencies_gemfile = File.expand_path("../Gemfile-rails-dependencies", __FILE__)
eval_gemfile rails_dependencies_gemfile

gem 'radius-spec', require: false, group: %i[development test] if RUBY_VERSION.to_f >= 2.5
