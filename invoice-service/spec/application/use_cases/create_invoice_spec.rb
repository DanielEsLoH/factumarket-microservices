# Unit tests for CreateInvoice use case
# Tests the orchestration logic and business flow

require 'date'
require_relative '../../../app/application/use_cases/create_invoice'
require_relative '../../../app/domain/entities/invoice'

RSpec.describe Application::UseCases::CreateInvoice do
  let(:invoice_repository) { double('InvoiceRepository') }
  let(:customer_validator) { double('CustomerValidator') }
  let(:event_publisher) { double('EventPublisher') }

  let(:use_case) do
    Application::UseCases::CreateInvoice.new(
      invoice_repository: invoice_repository,
      customer_validator: customer_validator,
      event_publisher: event_publisher
    )
  end

  let(:valid_invoice_data) do
    {
      customer_id: 1,
      amount: 1000.0,
      emission_date: Date.today
    }
  end

  describe '#execute' do
    context 'when customer does not exist' do
      it 'returns failure result with error message' do
        allow(customer_validator).to receive(:exists?).with(1).and_return(false)

        result = use_case.execute(valid_invoice_data)

        expect(result[:success]).to be false
        expect(result[:message]).to eq('Cliente no encontrado o inválido')
        expect(result[:data]).to be_nil
      end

      it 'does not call repository or event publisher' do
        allow(customer_validator).to receive(:exists?).with(1).and_return(false)

        expect(invoice_repository).not_to receive(:save)
        expect(event_publisher).not_to receive(:publish)

        use_case.execute(valid_invoice_data)
      end
    end

    context 'when invoice data is invalid' do
      let(:invalid_invoice_data) do
        {
          customer_id: 1,
          amount: -100,  # Invalid: negative amount
          emission_date: Date.today
        }
      end

      it 'returns failure result with validation errors' do
        allow(customer_validator).to receive(:exists?).with(1).and_return(true)

        result = use_case.execute(invalid_invoice_data)

        expect(result[:success]).to be false
        expect(result[:message]).to include('Amount must be greater than 0')
        expect(result[:data]).to be_nil
      end

      it 'does not persist the invoice' do
        allow(customer_validator).to receive(:exists?).with(1).and_return(true)

        expect(invoice_repository).not_to receive(:save)

        use_case.execute(invalid_invoice_data)
      end
    end

    context 'when all validations pass' do
      let(:saved_invoice) do
        Domain::Entities::Invoice.new(
          id: 123,
          customer_id: 1,
          amount: 1000.0,
          emission_date: Date.today,
          status: 'pending'
        )
      end

      before do
        allow(customer_validator).to receive(:exists?).with(1).and_return(true)
        allow(invoice_repository).to receive(:save).and_return(saved_invoice)
        allow(event_publisher).to receive(:publish)
      end

      it 'validates customer exists' do
        expect(customer_validator).to receive(:exists?).with(1).and_return(true)
        use_case.execute(valid_invoice_data)
      end

      it 'saves the invoice via repository' do
        expect(invoice_repository).to receive(:save).and_return(saved_invoice)
        use_case.execute(valid_invoice_data)
      end

      it 'publishes invoice.created event' do
        expect(event_publisher).to receive(:publish).with('invoice.created', saved_invoice.to_h)
        use_case.execute(valid_invoice_data)
      end

      it 'returns success result with invoice data' do
        result = use_case.execute(valid_invoice_data)

        expect(result[:success]).to be true
        expect(result[:message]).to eq('Factura creada exitosamente')
        expect(result[:data]).to eq(saved_invoice.to_h)
        expect(result[:data][:id]).to eq(123)
        expect(result[:data][:amount]).to eq(1000.0)
      end
    end

    context 'when repository raises an error' do
      before do
        allow(customer_validator).to receive(:exists?).with(1).and_return(true)
        allow(invoice_repository).to receive(:save).and_raise(StandardError, 'Database error')
        allow(event_publisher).to receive(:publish)
      end

      it 'publishes error event' do
        expect(event_publisher).to receive(:publish).with('invoice.error', hash_including(error: 'Database error'))
        use_case.execute(valid_invoice_data)
      end

      it 'returns failure result with error message' do
        result = use_case.execute(valid_invoice_data)

        expect(result[:success]).to be false
        expect(result[:message]).to include('Error interno')
        expect(result[:message]).to include('Database error')
      end
    end
  end
end
