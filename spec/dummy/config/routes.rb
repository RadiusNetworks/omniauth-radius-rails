Rails.application.routes.draw do
  mount Kracken::Engine => "/auth"
  get "welcome/index"
  get "welcome/secure_page"
end
