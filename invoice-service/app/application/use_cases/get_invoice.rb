# Application Layer - Get Invoice Use Case
# Retrieves a single invoice by ID

module Application
  module UseCases
    class GetInvoice
      def initialize(invoice_repository:, event_publisher:)
        @invoice_repository = invoice_repository
        @event_publisher = event_publisher
      end

      def execute(invoice_id)
        # Find invoice
        invoice = @invoice_repository.find_by_id(invoice_id)

        return failure_result('Factura no encontrada') if invoice.nil?

        # Publish event for audit
        @event_publisher.publish('invoice.fetched', invoice.to_h)

        # Return success
        success_result(invoice)
      rescue => e
        Rails.logger.error "Error in GetInvoice use case: #{e.message}"
        @event_publisher.publish('invoice.error', { error: e.message, invoice_id: invoice_id })
        failure_result("Error interno: #{e.message}")
      end

      private

      def success_result(invoice)
        {
          success: true,
          data: invoice.to_h
        }
      end

      def failure_result(error_message)
        {
          success: false,
          data: nil,
          message: error_message
        }
      end
    end
  end
end
