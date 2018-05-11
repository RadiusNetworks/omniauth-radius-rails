# frozen_string_literal: true

OmniAuth.config.test_mode = true

module OAuthHelper
  OAuthUser = OpenStruct.new(provider: 'radius',
                             uid: '0',
                             name: 'Joe',
                             email: 'jcool@peanuts.com')
                        .freeze

  module_function
  def new_oauth_user_hash(user)
    OmniAuth::AuthHash.new({
      provider: user.provider,
      uid: user.uid,
      extra: {
        raw_info: {
          attributes: {
            user:{
              first_name: user.name,
              email: user.email,
            }
      } } }
    })
  end

  module Request
    include OAuthHelper

    def authenticate_request!(user = OAuthUser)
      OmniAuth.config.mock_auth[:radius] = new_oauth_user_hash(user)

      get "/auth/radius"
      get response.header['Location']

      _request = nil
    end
  end
end

if defined? RSpec
  RSpec.configure do |c|
    c.include OAuthHelper::Request, type: :request
  end
end
