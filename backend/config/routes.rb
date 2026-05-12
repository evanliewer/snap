Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # --- iOS / JSON API ---
  namespace :api do
    namespace :v1 do
      post "signup", to: "sessions#signup"
      post "login",  to: "sessions#create"
      delete "logout", to: "sessions#destroy"

      get "me", to: "me#show"

      post "games/join", to: "games#join"
      resources :games, only: %i[create show update destroy] do
        member do
          get :leaderboard
          get :activity
          post :start
          post :end
        end
        resources :teams, only: %i[index create update destroy] do
          post :join, on: :member
        end
        resources :mission_categories, only: %i[index create update destroy], path: "categories"
        resources :missions, only: %i[index create update destroy]
        get "submissions", to: "submissions#index_for_game"
      end

      resources :missions, only: [] do
        get  "submissions", to: "submissions#index_for_mission"
        post "submissions", to: "submissions#create"
      end

      resources :submissions, only: %i[update destroy]
    end
  end

  # --- Admin web UI ---
  scope module: :web do
    get  "login",  to: "sessions#new",     as: :login
    post "login",  to: "sessions#create"
    delete "logout", to: "sessions#destroy", as: :logout
    get  "signup", to: "registrations#new", as: :signup
    post "signup", to: "registrations#create"

    resources :games do
      resources :teams,             except: %i[show]
      resources :mission_categories, except: %i[show], path: "categories"
      resources :missions,          except: %i[show]
      resources :submissions, only: %i[index update destroy], shallow: true
      member do
        post :start
        post :end
      end
    end
  end

  root "web/dashboards#show"
end
