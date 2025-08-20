Rails.application.routes.draw do
  get 'auth/:provider/callback', to: 'sessions#create'
  get '/login', to: 'sessions#new'
  delete '/logout', to: 'sessions#destroy', as: :logout
  resource :session, only: [:destroy]
  post "/guest_login", to: "sessions#guest"
  root "welcome#index"
  get "/home", to: "home#index", as: :home

  resources :games, only: :create do
    scope module: :games do
      resource :play,   only: :show
      resource :action, only: :create
    end
  end
end
