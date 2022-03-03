# frozen_string_literal: true

require 'redis'

module Kracken
  module SessionManager
    def self.conn
      @conn ||=
        begin
          default_redis_options = { url: ENV['REDIS_SESSION_URL'] }
          redis_options = default_redis_options.merge(Kracken.config.redis_options).compact

          if redis_options.any?
            Redis.new(**redis_options)
          else
            NullRedis.new
          end
        end
    end

    # @api private
    # For use in testing only
    def self.reset_conn
      @conn = nil
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
