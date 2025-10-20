Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Audit API endpoints (Auditoria)
  # GET /auditoria - List all audit events with filters
  # GET /auditoria/:factura_id - Get audit events for specific invoice
  resources :auditoria, only: [:index, :show]
end
