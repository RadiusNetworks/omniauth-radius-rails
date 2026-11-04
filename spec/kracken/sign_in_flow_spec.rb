# frozen_string_literal: true

require 'rails_helper'

# End-to-end cover for the OmniAuth 2 request phase. OmniAuth 2 accepts the
# request phase only over POST and validates it against Rails' authenticity
# token, so the interstitial has to produce a form that OmniAuth's verifier
# actually accepts. Asserting the controller renders *a* form would not catch
# a token the verifier rejects, so drive the real middleware here.
RSpec.describe "Sign in request phase", type: :request do
  around do |example|
    original_test_mode = OmniAuth.config.test_mode
    # The real request phase, not the mock, so `request_validation_phase`
    # (Rails CSRF) and the POST-only restriction both run.
    OmniAuth.config.test_mode = false
    begin
      example.run
    ensure
      OmniAuth.config.test_mode = original_test_mode
    end
  end

  def form_token
    # Pull the token the interstitial rendered, the way a browser would.
    body = response.body
    body[/name="authenticity_token"[^>]*value="([^"]+)"/, 1] ||
      body[/value="([^"]+)"[^>]*name="authenticity_token"/, 1]
  end

  describe "GET the interstitial" do
    it "renders a form that posts to the OmniAuth request path" do
      get "/auth/sign_in", params: { origin: "/reports/7" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('action="/auth/radius?origin=%2Freports%2F7"')
      expect(response.body).to include('method="post"')
      expect(form_token).to be_present
    end

    it "ignores an off-site origin rather than reflecting it" do
      get "/auth/sign_in", params: { origin: "//evil.example.com/x" }

      expect(response.body).to include('action="/auth/radius"')
      expect(response.body).not_to include("evil.example.com")
    end
  end

  describe "POSTing that form to OmniAuth" do
    it "is accepted and redirects to the provider" do
      get "/auth/sign_in", params: { origin: "/reports/7" }

      post "/auth/radius?origin=%2Freports%2F7",
           params: { authenticity_token: form_token }

      expect(response).to have_http_status(:found)
      expect(response.headers["Location"])
        .to start_with("#{Kracken::PROVIDER_URL}/auth/radius/authorize")
    end
  end

  describe "the GET request phase OmniAuth 1 allowed" do
    # The CVE-2015-9284 fix: a plain link can no longer start sign in, which
    # is exactly why `redirect_to_sign_in` goes via the interstitial.
    it "does not start sign in" do
      get "/auth/radius"

      expect(response).to have_http_status(:not_found)
      expect(response.headers["Location"]).to be_nil
    end
  end
end
