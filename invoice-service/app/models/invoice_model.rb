# Infrastructure Layer - ActiveRecord Model for Oracle persistence
# This is NOT a domain entity - it's a data mapper for Oracle database
# Separated from domain logic to maintain Clean Architecture

class InvoiceModel < ApplicationRecord
  self.table_name = 'invoices'

  # Basic validations at database level
  validates :customer_id, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :emission_date, presence: true
  validates :status, presence: true
end
