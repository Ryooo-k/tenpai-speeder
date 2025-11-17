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

  resources :favorites, param: :game_id, only: [:index, :create, :destroy]

  resources :games, only: :create do
    scope module: :games do
      get  'play', to: 'plays#show',    as: :play
      post 'play', to: 'plays#command', as: :play_command
      post 'play/undo', to: 'plays#undo', as: :play_undo
      post 'play/redo', to: 'plays#redo', as: :play_redo
      post 'play/playback', to: 'plays#playback', as: :play_playback
    end
  end
end
