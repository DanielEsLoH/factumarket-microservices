Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Invoice API endpoints (Facturas)
  resources :facturas, only: [:create, :show, :index]
end
