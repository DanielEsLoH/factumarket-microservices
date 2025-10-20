# Infrastructure Layer - Oracle Invoice Repository Implementation
# Implements the Domain Repository interface using ActiveRecord (Oracle)
# Converts between ActiveRecord models and Domain entities

module Infrastructure
  module Persistence
    class OracleInvoiceRepository < Domain::Repositories::InvoiceRepository
      def save(invoice_entity)
        # Convert domain entity to ActiveRecord model
        invoice_model = InvoiceModel.new(
          customer_id: invoice_entity.customer_id,
          amount: invoice_entity.amount,
          emission_date: invoice_entity.emission_date,
          status: invoice_entity.status
        )

        invoice_model.save!

        # Convert back to domain entity with persisted data
        to_domain_entity(invoice_model)
      end

      def find_by_id(id)
        invoice_model = InvoiceModel.find_by(id: id)
        return nil if invoice_model.nil?

        to_domain_entity(invoice_model)
      end

      def find_by_date_range(start_date, end_date)
        invoice_models = InvoiceModel.where(emission_date: start_date..end_date)
                                      .order(emission_date: :desc)

        invoice_models.map { |model| to_domain_entity(model) }
      end

      def find_all
        invoice_models = InvoiceModel.all.order(created_at: :desc)
        invoice_models.map { |model| to_domain_entity(model) }
      end

      private

      # Convert ActiveRecord model to Domain entity
      def to_domain_entity(invoice_model)
        Domain::Entities::Invoice.new(
          id: invoice_model.id,
          customer_id: invoice_model.customer_id,
          amount: invoice_model.amount,
          emission_date: invoice_model.emission_date,
          status: invoice_model.status,
          created_at: invoice_model.created_at,
          updated_at: invoice_model.updated_at
        )
      end
    end
  end
end
