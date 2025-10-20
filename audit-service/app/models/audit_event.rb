# Audit Event Model - MongoDB Document
# Stores all audit events from Customer and Invoice services
# Uses Mongoid ODM

class AuditEvent
  include Mongoid::Document
  include Mongoid::Timestamps

  # Fields
  field :event_type, type: String        # e.g., "customer.created", "invoice.fetched"
  field :service, type: String           # e.g., "customer_service", "invoice_service"
  field :entity_type, type: String       # e.g., "Customer", "Invoice"
  field :entity_id, type: Integer        # ID of the entity
  field :timestamp, type: Time           # When the event occurred
  field :metadata, type: Hash            # Full payload data
  field :http_method, type: String       # POST, GET, PUT, DELETE
  field :endpoint, type: String          # e.g., "/clientes", "/facturas/123"

  # Indexes for efficient querying
  index({ event_type: 1 })
  index({ entity_type: 1, entity_id: 1 })
  index({ timestamp: -1 })
  index({ service: 1 })

  # Validations
  validates :event_type, presence: true
  validates :service, presence: true
  validates :timestamp, presence: true
end
