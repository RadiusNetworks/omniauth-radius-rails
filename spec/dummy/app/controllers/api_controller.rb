# frozen_string_literal: true

class ApiController < ActionController::Base
  include Kracken::Controllers::TokenAuthenticatable
  include Kracken::Controllers::JsonApiCompatible

  def index
    render json: { remember: "Always bring a banana to a party" }
  end
end
