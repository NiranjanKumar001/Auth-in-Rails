Rails.application.routes.draw do
  root "sessions#new"

  # Web routes
  get  "/signup", to: "users#new", as: "signup"
  post "/signup", to: "users#create"

  get  "/login",  to: "sessions#new", as: "login"
  post "/login",  to: "sessions#create"

  get  "/dashboard", to: "dashboard#index", as: "dashboard"
  get  "/users", to: "users#index", as: "users" # List all users

  delete "/logout", to: "sessions#destroy", as: "logout"

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication endpoints
      post "/auth/login", to: "sessions#create"
      post "/auth/register", to: "users#create"
      delete "/auth/logout", to: "sessions#destroy"
      post "/auth/refresh", to: "sessions#refresh"

      # User endpoints
      get "/users/me", to: "users#me"
      get "/users", to: "users#index"

      # Dashboard endpoint
      get "/dashboard", to: "dashboard#index"
    end
  end

  # Alternative API endpoints (without namespace for simplicity)
  scope path: "/api", defaults: { format: :json } do
    post "/login", to: "sessions#create"
    post "/register", to: "users#create"
    delete "/logout", to: "sessions#destroy"
    post "/refresh", to: "sessions#refresh"
    get "/me", to: "users#me"
    get "/dashboard", to: "dashboard#index"
    get "/users", to: "users#index"
  end
end
