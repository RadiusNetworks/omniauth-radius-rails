module Kracken
  class BaseControllerDouble
    Request = Struct.new(:env)

    attr_accessor :session, :cookies, :request, :params

    def initialize
      @session = {}
      @cookies = {}
      @request = Request.new({})
      @params = {}
    end

    def self.helper_method(*) ; end
    def self.before_action(*) ; end
    def self.skip_before_action(*) ; end

    def root_url
      "/"
    end
  end
end
