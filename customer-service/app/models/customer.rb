# Customer Model
# Represents a customer in the Oracle database
# Business domain: person or company that can receive invoices

class Customer < ApplicationRecord
  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 255 }
  validates :identification, presence: true, uniqueness: true, length: { minimum: 5, maximum: 50 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :address, presence: true, length: { minimum: 5, maximum: 500 }

  # Callbacks
  after_create :publish_created_event
  after_find :publish_fetched_event

  private

  def publish_created_event
    EventPublisher.publish('customer.created', customer_payload)
  rescue => e
    Rails.logger.error "Failed to publish customer.created event: #{e.message}"
  end

  def publish_fetched_event
    EventPublisher.publish('customer.fetched', customer_payload)
  rescue => e
    Rails.logger.error "Failed to publish customer.fetched event: #{e.message}"
  end

  def customer_payload
    {
      id: id,
      name: name,
      identification: identification,
      email: email,
      address: address,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
