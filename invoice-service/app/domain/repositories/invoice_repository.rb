# Domain Layer - Invoice Repository Interface
# Abstract interface for persistence (Dependency Inversion Principle)
# Infrastructure layer will implement this interface

module Domain
  module Repositories
    class InvoiceRepository
      # Abstract method: Save invoice
      def save(invoice_entity)
        raise NotImplementedError, 'Subclass must implement save method'
      end

      # Abstract method: Find invoice by ID
      def find_by_id(id)
        raise NotImplementedError, 'Subclass must implement find_by_id method'
      end

      # Abstract method: Find invoices by date range
      def find_by_date_range(start_date, end_date)
        raise NotImplementedError, 'Subclass must implement find_by_date_range method'
      end

      # Abstract method: Find all invoices
      def find_all
        raise NotImplementedError, 'Subclass must implement find_all method'
      end
    end
  end
end
