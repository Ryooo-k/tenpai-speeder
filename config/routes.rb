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
      resource :play, only: :show

      post 'action/draw',    to: 'actions#draw'
      get 'action/choose',   to: 'actions#choose'
      post 'action/discard', to: 'actions#discard'
      post 'action/ron',     to: 'actions#ron'
      post 'action/furo',    to: 'actions#furo'
      post 'action/tsumo',   to: 'actions#tsumo'
      post 'action/through', to: 'actions#through'
      get  'action/pass',    to: 'actions#pass'
    end
  end
end
