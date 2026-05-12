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
      resources :games, only: %i[show] do
        member do
          get :leaderboard
          get :activity
        end
        resources :teams, only: %i[index create] do
          post :join, on: :member
        end
        resources :missions, only: %i[index]
      end

      resources :missions, only: [] do
        resources :submissions, only: %i[index create]
      end
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
