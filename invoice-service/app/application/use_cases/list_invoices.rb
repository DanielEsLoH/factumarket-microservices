# Application Layer - List Invoices Use Case
# Retrieves invoices with optional date range filtering

module Application
  module UseCases
    class ListInvoices
      def initialize(invoice_repository:, event_publisher:)
        @invoice_repository = invoice_repository
        @event_publisher = event_publisher
      end

      def execute(filters = {})
        invoices = if filters[:fecha_inicio] && filters[:fecha_fin]
          # Filter by date range
          @invoice_repository.find_by_date_range(
            Date.parse(filters[:fecha_inicio]),
            Date.parse(filters[:fecha_fin])
          )
        else
          # Get all invoices
          @invoice_repository.find_all
        end

        # Publish event for audit
        @event_publisher.publish('invoice.listed', { count: invoices.count, filters: filters })

        # Return success
        success_result(invoices)
      rescue => e
        Rails.logger.error "Error in ListInvoices use case: #{e.message}"
        @event_publisher.publish('invoice.error', { error: e.message, filters: filters })
        failure_result("Error interno: #{e.message}")
      end

      private

      def success_result(invoices)
        {
          success: true,
          count: invoices.count,
          data: invoices.map(&:to_h)
        }
      end

      def failure_result(error_message)
        {
          success: false,
          data: [],
          message: error_message
        }
      end
    end
  end
end
