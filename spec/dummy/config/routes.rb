# frozen_string_literal: true

Rails.application.routes.draw do
  mount Kracken::Engine => "/auth"
  get "welcome/index"
  get "welcome/secure_page"
  get "api/index"
end
