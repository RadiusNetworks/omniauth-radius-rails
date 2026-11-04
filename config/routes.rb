# frozen_string_literal: true

Kracken::Engine.routes.draw do
  get '/sign_in', to: 'sessions#new', as: :start_sign_in
  get '/:provider/callback', to: 'sessions#create'
  get '/failure', to: 'sessions#failure'
  delete '/sign_out', to: 'sessions#destroy'
  get '/webhook/:uid', to: 'sync#user'
end
