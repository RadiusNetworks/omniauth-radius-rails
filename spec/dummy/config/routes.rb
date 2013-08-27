Rails.application.routes.draw do

  mount Kracken::Engine => "/auth"
end
