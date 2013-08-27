Kracken::Engine.routes.draw do
  get '/:provider/callback', to: 'sessions#create'
  get '/failure', to: 'sessions#failure'
  get '/sign_out', to: 'sessions#destroy'
end
