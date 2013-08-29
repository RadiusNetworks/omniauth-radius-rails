Rails.application.routes.draw do
  mount Kracken::Engine => "/auth"
  get "welcome/index"
end
