Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  resource :session, only: %i[ new create destroy ]
  resource :leaderboard, only: :show
  resource :play, only: :show
  resource :decay, only: %i[ create destroy ]
  resource :admin, only: :show
  resource :backup, only: :create
  resources :debts, only: :index do
    resource :payment, only: %i[ create destroy ], module: :debts
  end
  resources :debt_settlements, only: :create
  resources :games, only: %i[ index show create edit update destroy ]
  resources :teams, only: :show
  resources :players, only: %i[ index show create update ]
  resource :head_to_head, only: :show

  root "leaderboards#show"
end
