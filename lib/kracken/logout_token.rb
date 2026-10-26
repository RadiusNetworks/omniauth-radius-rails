# frozen_string_literal: true

require "openssl"

module Kracken
  # Builds the signed URL that hands a sign out off to the account server.
  #
  # The client app ends its own session with a CSRF-protected DELETE, then
  # redirects the browser to `<provider>/users/client_sign_out` with:
  #
  #   client_id, uid, ts, redirect_to, sig
  #
  # where `sig` is:
  #
  #   HMAC-SHA256(app_secret, "logout|<client_id>|<uid>|<ts>|<redirect_to>")
  #
  # Only the client app knows `app_secret`, so a third-party page can't forge
  # the URL. The account server rejects tokens older than a few minutes.
  module LogoutToken
  module_function

    def url(uid:, redirect_to:, now: Time.current)
      client_id = Kracken.config.app_id.to_s
      timestamp = now.to_i.to_s
      params = {
        client_id: client_id,
        uid: uid.to_s,
        ts: timestamp,
        redirect_to: redirect_to.to_s,
      }
      params[:sig] = signature(
        Kracken.config.app_secret,
        client_id: client_id,
        uid: uid,
        timestamp: timestamp,
        redirect_to: redirect_to,
      )

      "#{Kracken.config.provider_url}/users/client_sign_out?#{params.to_query}"
    end

    def signature(app_secret, client_id:, uid:, timestamp:, redirect_to:)
      payload = ["logout", client_id, uid, timestamp, redirect_to].join("|")
      OpenSSL::HMAC.hexdigest("SHA256", app_secret.to_s, payload)
    end
  end
end
