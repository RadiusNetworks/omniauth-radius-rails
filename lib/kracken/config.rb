module Kracken
  Config = Struct.new( :app_id, :app_secret, :provider_url) do
    def url
      provider_url || "https://account.messageradius.com"
    end
  end
end
