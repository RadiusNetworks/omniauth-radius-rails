# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OmniAuth::Strategies::Radius do
  subject(:strategy) { described_class.new(app, 'client-id', 'client-secret') }

  let(:app) { ->(_env) { [200, {}, ['ok']] } }
  let(:session) { {} }
  let(:env) do
    Rack::MockRequest.env_for('http://app.example.com/auth/radius').merge('rack.session' => session)
  end

  # RFC 7636 section 4.1 (verifier) and 4.2 (S256 challenge, unpadded base64url)
  def s256(verifier)
    Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
  end

  before { strategy.instance_variable_set(:@env, env) }

  it 'enables PKCE' do
    expect(strategy.options.pkce).to be true
  end

  describe '#authorize_params' do
    it 'includes an S256 code_challenge' do
      params = strategy.authorize_params

      expect(params[:code_challenge_method]).to eq 'S256'
      expect(params[:code_challenge]).to match(/\A[A-Za-z0-9\-_]{43}\z/)
    end

    it 'stores a valid code_verifier in the session that hashes to the challenge' do
      params = strategy.authorize_params
      verifier = session['omniauth.pkce.verifier']

      expect(verifier).to match(/\A[A-Za-z0-9\-._~]{43,128}\z/)
      expect(params[:code_challenge]).to eq s256(verifier)
    end

    it 'generates a fresh verifier for every authorization request' do
      first = strategy.authorize_params[:code_challenge]
      second = strategy.authorize_params[:code_challenge]

      expect(first).not_to eq second
    end

    it 'still includes state' do
      params = strategy.authorize_params

      expect(params[:state]).to be_present
      expect(session['omniauth.state']).to eq params[:state]
    end
  end

  describe '#request_phase' do
    it 'redirects to the provider with the PKCE params' do
      _status, headers, _body = strategy.request_phase
      query = Rack::Utils.parse_query(URI.parse(headers['Location']).query)

      expect(query['code_challenge_method']).to eq 'S256'
      expect(query['code_challenge']).to eq s256(session['omniauth.pkce.verifier'])
    end
  end

  describe '#token_params' do
    it 'includes the code_verifier matching the authorize challenge' do
      challenge = strategy.authorize_params[:code_challenge]
      verifier = strategy.token_params[:code_verifier]

      expect(verifier).to be_present
      expect(s256(verifier)).to eq challenge
    end

    it 'consumes the verifier from the session so it cannot be reused' do
      strategy.authorize_params
      strategy.token_params

      expect(session).not_to have_key 'omniauth.pkce.verifier'
    end
  end

  describe 'token request' do
    it 'sends the code_verifier to the token endpoint' do
      challenge = strategy.authorize_params[:code_challenge]
      sent = nil
      stub_request(:post, %r{\A#{Regexp.escape(described_class.provider_url)}/})
        .to_return do |request|
          sent = Rack::Utils.parse_query(request.body)
          {
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: { access_token: 'token', token_type: 'bearer' }.to_json,
          }
        end
      callback_env = Rack::MockRequest.env_for('http://app.example.com/auth/radius/callback?code=abc123')
                                      .merge('rack.session' => session)
      strategy.instance_variable_set(:@env, callback_env)

      token = strategy.send(:build_access_token)

      expect(token.token).to eq 'token'
      expect(sent['code']).to eq 'abc123'
      expect(sent['grant_type']).to eq 'authorization_code'
      expect(s256(sent['code_verifier'])).to eq challenge
    end
  end
end
