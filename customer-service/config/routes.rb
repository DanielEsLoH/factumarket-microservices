Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Customer API endpoints (Clientes)
  resources :clientes, only: [:create, :show, :index]
end
