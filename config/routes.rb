Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "welcome#index"
  get "/home", to: "home#index", as: :home
  resources :games, only: [:create]
  get "/game/:id/play", to: "game_plays#show", as: :game_play
end
