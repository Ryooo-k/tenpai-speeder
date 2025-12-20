Rails.application.routes.draw do
  get 'up', to: 'rails/health#show', as: :rails_health_check

  get 'auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: redirect('/')
  get '/login', to: 'sessions#new'
  delete '/logout', to: 'sessions#destroy', as: :logout
  resource :session, only: [:destroy]
  post '/guest_login', to: 'sessions#guest'
  root 'welcome#index'
  get '/home', to: 'home#index', as: :home
  get '/terms', to: 'terms#show', as: :terms
  get '/privacy', to: 'privacy#show', as: :privacy

  resources :favorites, param: :game_id, only: [:index, :create, :destroy]

  resources :games, only: :create do
    scope module: :games do
      resource :play,     only: :show,   path: 'play',          as: :play
      resource :command,  only: :create, path: 'play/commands', as: :play_command
      resource :backward, only: :update, path: 'play/backward', as: :play_backward
      resource :progress, only: :update, path: 'play/progress', as: :play_progress
      resource :playback, only: :update, path: 'play/playback', as: :play_playback
    end
  end
end
