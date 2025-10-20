# Application Layer - Create Invoice Use Case
# Orchestrates business logic for creating an invoice
# Dependencies are injected (Dependency Injection)

module Application
  module UseCases
    class CreateInvoice
      def initialize(invoice_repository:, customer_validator:, event_publisher:)
        @invoice_repository = invoice_repository
        @customer_validator = customer_validator
        @event_publisher = event_publisher
      end

      def execute(invoice_data)
        # Step 1: Validate that customer exists (external validation)
        unless @customer_validator.exists?(invoice_data[:customer_id])
          return failure_result('Cliente no encontrado o inválido')
        end

        # Step 2: Create domain entity
        invoice = Domain::Entities::Invoice.new(invoice_data)

        # Step 3: Validate business rules
        unless invoice.valid?
          return failure_result(invoice.errors.join(', '))
        end

        # Step 4: Persist invoice
        saved_invoice = @invoice_repository.save(invoice)

        # Step 5: Publish event for audit
        @event_publisher.publish('invoice.created', saved_invoice.to_h)

        # Step 6: Return success result
        success_result(saved_invoice)
      rescue => e
        # Log error if Rails logger is available
        Rails.logger.error("Error in CreateInvoice use case: #{e.message}") if defined?(Rails)
        @event_publisher.publish('invoice.error', { error: e.message, data: invoice_data })
        failure_result("Error interno: #{e.message}")
      end

      private

      def success_result(invoice)
        {
          success: true,
          data: invoice.to_h,
          message: 'Factura creada exitosamente'
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
