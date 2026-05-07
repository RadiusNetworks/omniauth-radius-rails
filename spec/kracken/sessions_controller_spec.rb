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
end
