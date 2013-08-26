Kracken::Engine.routes.draw do
  get '/auth/:provider/callback', to: 'kracken/sessions#create'
  get '/auth/failure', to: 'kracken/sessions#failure'
  get '/sign_out', to: 'kracken/sessions#destroy'
end
