# frozen_string_literal: true

# In memory user model
class User
  @@users = {}

  def self.find(id)
    @@users[id]
  end

  def self.find_or_create_from_auth_hash(hash)
    user = self.new(hash)
    @@users[hash["uid"]] = user
  end

  def initialize(hash)
    @hash = hash
  end

  def id
    @hash["uid"]
  end

  def uid
    @hash["uid"]
  end

  def team_ids
    @hash["info"] ||= {}
    @hash["info"]["teams"] ||= []
    @hash["info"]["teams"].map { |t| t["uid"] }
  end
end
