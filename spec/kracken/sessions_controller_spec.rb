# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Kracken::SessionsController, type: :controller do
  routes { Kracken::Engine.routes }

  let(:auth_hash) { OmniAuth::AuthHash.new(Kracken::Fixtures.auth_hash) }
  let(:user_double) { double(:user, id: "1", uid: "1", admin: false) }

  before do
    allow(User).to receive(:find_or_create_from_auth_hash).and_return(user_double)
    allow(Kracken::SessionManager).to receive(:get).and_return(nil)
    request.env['omniauth.auth'] = auth_hash
  end

  describe "GET :create" do
    context "with a safe relative origin" do
      it "redirects to the origin path" do
        request.env['omniauth.origin'] = '/admin/projects/1'
        get :create, params: { provider: 'radius' }
        expect(response).to redirect_to('/admin/projects/1')
      end

      it "redirects to root when origin is '/'" do
        request.env['omniauth.origin'] = '/'
        get :create, params: { provider: 'radius' }
        expect(response).to redirect_to('/')
      end
    end

    context "with a protocol-relative URL" do
      it "redirects to root for //yahoo.com" do
        request.env['omniauth.origin'] = '//yahoo.com'
        get :create, params: { provider: 'radius' }
        expect(response).to redirect_to('/')
      end

      it "redirects to root for //yahoo.com/path" do
        request.env['omniauth.origin'] = '//yahoo.com/path'
        get :create, params: { provider: 'radius' }
        expect(response).to redirect_to('/')
      end
    end

    context "with an absolute URL" do
      it "redirects to root" do
        request.env['omniauth.origin'] = 'https://yahoo.com'
        get :create, params: { provider: 'radius' }
        expect(response).to redirect_to('/')
      end
    end

    context "with no origin" do
      it "redirects to root" do
        request.env['omniauth.origin'] = nil
        get :create, params: { provider: 'radius' }
        expect(response).to redirect_to('/')
      end
    end
  end

  describe "DELETE :destroy" do
    let(:now) { Time.at(1_800_000_000).utc }

    around do |example|
      original = [Kracken.config.app_id, Kracken.config.app_secret]
      Kracken.config.app_id = "captain"
      Kracken.config.app_secret = "shh"
      begin
        example.run
      ensure
        Kracken.config.app_id, Kracken.config.app_secret = original
      end
    end

    before do
      allow(Time).to receive(:now).and_return(now)
    end

    it "clears the session" do
      session[:user_id] = "1"
      session[:user_uid] = "42"
      delete :destroy
      expect(session[:user_id]).to be_nil
      expect(session[:user_uid]).to be_nil
    end

    it "hands off to the account server with a signed logout token" do
      session[:user_uid] = "42"
      delete :destroy

      location = URI(response.location)
      params = Rack::Utils.parse_query(location.query)
      expect("#{location.scheme}://#{location.host}#{location.path}")
        .to eq "#{Kracken.config.provider_url}/users/client_sign_out"
      expect(params).to include(
        "client_id" => "captain",
        "uid" => "42",
        "ts" => "1800000000",
        "redirect_to" => "http://test.host",
      )
      expect(params["sig"]).to eq OpenSSL::HMAC.hexdigest(
        "SHA256", "shh", "logout|captain|42|1800000000|http://test.host"
      )
    end

    it "asks the account server to confirm when no user is signed in" do
      delete :destroy
      expect(response).to redirect_to(
        "#{Kracken.config.provider_url}/users/sign_out?redirect_to=http%3A%2F%2Ftest.host",
      )
    end

    # rspec-rails disables forgery protection in controller specs, so turn it
    # back on to prove a forged or stale sign out is handled.
    context "without a valid authenticity token" do
      before do
        controller.allow_forgery_protection = true
      end

      it "keeps the session" do
        session[:user_id] = "1"
        session[:user_uid] = "42"
        delete :destroy
        expect(session[:user_id]).to eq "1"
        expect(session[:user_uid]).to eq "42"
      end

      it "asks the account server to confirm instead of sending a logout token" do
        session[:user_uid] = "42"
        delete :destroy
        expect(response).to redirect_to(
          "#{Kracken.config.provider_url}/users/sign_out?redirect_to=http%3A%2F%2Ftest.host",
        )
      end
    end
  end

  describe "routing" do
    it "only signs out on DELETE" do
      expect(delete: "/sign_out").to route_to("kracken/sessions#destroy")
      expect(get: "/sign_out").not_to be_routable
    end
  end

  describe "GET :failure" do
    it "renders a generic failure message as unauthorized plain text" do
      get :failure

      expect(response).to have_http_status(:unauthorized)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to eq("Sorry, we couldn't sign you in. Please try again.")
    end

    it "does not reflect OmniAuth failure params" do
      get :failure, params: { message: "Call 555-0100", strategy: "evil", origin: "//evil.example" }

      expect(response.body).to eq("Sorry, we couldn't sign you in. Please try again.")
    end
  end
end
