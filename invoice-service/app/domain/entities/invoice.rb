# Domain Layer - Invoice Entity
# Pure Ruby class with business logic
# No dependencies on Rails or infrastructure

module Domain
  module Entities
    class Invoice
      attr_reader :id, :customer_id, :amount, :emission_date, :status, :created_at, :updated_at

      def initialize(attributes = {})
        @id = attributes[:id]
        @customer_id = attributes[:customer_id]
        @amount = attributes[:amount]
        @emission_date = attributes.key?(:emission_date) ? attributes[:emission_date] : Date.today
        @status = attributes[:status] || 'pending'
        @created_at = attributes[:created_at]
        @updated_at = attributes[:updated_at]
      end

      # Business rule: Invoice is valid if all business rules pass
      def valid?
        errors.empty?
      end

      # Business validation errors
      def errors
        validation_errors = []
        validation_errors << 'Customer ID is required' if customer_id.nil?
        validation_errors << 'Amount must be greater than 0' unless amount_positive?
        validation_errors << 'Emission date cannot be in the future' unless emission_date_valid?
        validation_errors
      end

      # Business rule: Amount must be positive
      def amount_positive?
        return false if amount.nil?
        amount > 0
      end

      # Business rule: Emission date must not be in the future
      def emission_date_valid?
        return false if emission_date.nil?
        emission_date <= Date.today
      end

      # Business rule: Check if invoice can be cancelled
      def cancellable?
        status == 'pending' || status == 'issued'
      end

      # Business method: Calculate tax (example - 19% IVA)
      def calculate_tax
        (amount * 0.19).round(2)
      end

      # Business method: Calculate total with tax
      def total_with_tax
        (amount + calculate_tax).round(2)
      end

      def to_h
        {
          id: id,
          customer_id: customer_id,
          amount: amount,
          emission_date: emission_date,
          status: status,
          tax: calculate_tax,
          total: total_with_tax,
          created_at: created_at,
          updated_at: updated_at
        }
      end
    end
  end
end
