Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  resource :session, only: %i[ new create destroy ]
  resource :leaderboard, only: :show
  resources :games, only: %i[ index show create edit update destroy ]
  resources :teams, only: :show
  resources :players, only: :show
  resource :prediction, only: :show

  root "leaderboards#show"
end
