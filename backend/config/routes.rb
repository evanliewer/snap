Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount ActionCable.server => "/cable"

  # --- iOS / JSON API ---
  namespace :api do
    namespace :v1 do
      post "signup", to: "sessions#signup"
      post "login",  to: "sessions#create"
      delete "logout", to: "sessions#destroy"

      resources :password_resets, only: %i[create update], param: :id

      get "me", to: "me#show"

      post "games/join", to: "games#join"
      resources :games, only: %i[create show update destroy] do
        member do
          get :leaderboard
          get :activity
          post :start
          post :end
          post :duplicate
          patch :cover
          post :archive
          post :unarchive
        end
        resources :teams, only: %i[index create update destroy] do
          post :join, on: :member
          collection { post :reorder }
        end
        resources :mission_categories, only: %i[index create update destroy], path: "categories" do
          collection { post :reorder }
        end
        resources :missions, only: %i[index create update destroy] do
          collection { post :reorder }
        end
        get "submissions", to: "submissions#index_for_game"
      end

      resources :missions, only: [] do
        get  "submissions", to: "submissions#index_for_mission"
        post "submissions", to: "submissions#create"
      end

      resources :submissions, only: %i[update destroy] do
        resource :reactions, only: %i[create destroy]
        resources :comments, only: %i[index create]
      end
      resources :comments, only: %i[destroy]
      get "games/:game_id/players/:id", to: "players#show", as: :game_player

      get  "game_templates", to: "game_templates#index"
      post "games/:game_id/apply_template", to: "game_templates#apply"
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

  # Public spectator (no auth)
  get "g/:join_code",       to: "web/spectator#show",  as: :spectator
  get "g/:join_code/recap", to: "web/spectator#recap", as: :spectator_recap

  root "web/dashboards#show"
end
