Rails.application.routes.draw do
  root "sessions#new"

  get  "/signup", to: "users#new"
  post "/signup", to: "users#create"

  get  "/login",  to: "sessions#new"
  post "/login",  to: "sessions#create"

  get  "/dashboard", to: "dashboard#index"

  delete "/logout", to: "sessions#destroy"
end
