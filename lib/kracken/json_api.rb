require_relative 'json_api/exception_wrapper'
require_relative 'json_api/path'
require_relative 'json_api/public_exceptions'
require_relative 'json_api/routing_mapper'

module Kracken
  module JsonApi
    def self.has_path?(request)
      paths.any? { |path| path.matches?(request) }
    end

    def self.paths
      @paths ||= []
    end

    def self.add_path(path)
      paths << Path.new(path)
    end
  end
end
