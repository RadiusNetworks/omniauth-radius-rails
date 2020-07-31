class SessionManager
  def self.conn
    Redis.new(url: ENV["REDIS_SESSION_URL"])
  end

  def self.active?
    ENV["REDIS_SESSION_URL"].present?
  end

  def self.get(user_id)
    return unless active?

    conn.get(user_session_key(user_id))
  end

  def self.clear(user_id)
    return unless active?

    conn.del(user_session_key(user_id))
  end

  def self.update(user_id, value)
    return unless active?

    conn.set(user_session_key(user_id), value)
  end

  def self.user_session_key(user_id)
    "rnsession:#{user_id}"
  end
end
