Rails.application.routes.draw do
  get 'auth/:provider/callback', to: 'sessions#create'
  get '/login', to: 'sessions#new'
  delete '/logout', to: 'sessions#destroy', as: :logout
  resource :session, only: [:destroy]
  post "/guest_login", to: "sessions#guest"
  root "welcome#index"
  get "/home", to: "home#index", as: :home
  get "/terms", to: "terms#show", as: :terms
  get "/privacy", to: "privacy#show", as: :privacy

  resources :games, only: :create do
    scope module: :games do
      get  'play', to: 'plays#show',    as: :play
      post 'play', to: 'plays#command', as: :play_command
    end
  end
end
