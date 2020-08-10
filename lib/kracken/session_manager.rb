# frozen_string_literal: true

module Kracken
  module SessionManager
    def self.conn
      @conn ||= if ENV["REDIS_SESSION_URL"].present?
                  Redis.new(url: ENV["REDIS_SESSION_URL"])
                else
                  NullRedis.new
                end
    end

    def self.get(user_id)
      conn.get(user_session_key(user_id))
    end

    def self.del(user_id)
      conn.del(user_session_key(user_id))
    end

    def self.update(user_id, value)
      conn.set(user_session_key(user_id), value)
    end

    def self.user_session_key(user_id)
      "rnsession:#{user_id}"
    end

    class NullRedis
      # rubocop:disable Style/EmptyMethod
      def initialize(*); end

      def del(*); end

      def get(*); end

      def set(*); end
      # rubocop:enable Style/EmptyMethod
    end
  end
end
