# frozen_string_literal: true

module Kracken
  class BaseControllerDouble
    Request = Struct.new(:env, :controller_class, :path_parameters)

    attr_accessor :session, :cookies, :request, :params

    def initialize
      @session = {}
      @cookies = {}
      @params = { action: :index }
      @request = Request.new({}, self.class, @params.slice(:action))
    end

    def self.helper_method(*) ; end
    def self.before_action(*) ; end
    def self.skip_before_action(*) ; end

    def root_url
      "/"
    end
  end
end
