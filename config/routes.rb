Rails.application.routes.draw do
  root "sessions#new"

  get  "/signup", to: "users#new", as: "signup"
  post "/signup", to: "users#create"

  get  "/login",  to: "sessions#new", as: "login"
  post "/login",  to: "sessions#create"

  get  "/dashboard", to: "dashboard#index", as: "dashboard"

  delete "/logout", to: "sessions#destroy", as: "logout"
end
