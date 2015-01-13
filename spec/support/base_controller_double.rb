module Kracken
  class BaseControllerDouble
    attr_accessor :session

    def initialize
      @session = {}
    end

    def self.helper_method(*) ; end
    def self.before_action(*) ; end
    def self.skip_before_action(*) ; end

    def root_url
      "/"
    end
  end
end
