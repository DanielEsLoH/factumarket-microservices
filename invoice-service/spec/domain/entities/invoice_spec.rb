# Unit tests for Invoice domain entity
# Tests business rules and validations

require 'date'
require_relative '../../../app/domain/entities/invoice'

RSpec.describe Domain::Entities::Invoice do
  describe '#valid?' do
    context 'when invoice has valid data' do
      it 'returns true' do
        invoice = Domain::Entities::Invoice.new(
          customer_id: 1,
          amount: 1000.50,
          emission_date: Date.today
        )

        expect(invoice.valid?).to be true
      end
    end

    context 'when customer_id is nil' do
      it 'returns false and includes error message' do
        invoice = Domain::Entities::Invoice.new(
          customer_id: nil,
          amount: 1000.50,
          emission_date: Date.today
        )

        expect(invoice.valid?).to be false
        expect(invoice.errors).to include('Customer ID is required')
      end
    end

    context 'when amount is zero' do
      it 'returns false and includes error message' do
        invoice = Domain::Entities::Invoice.new(
          customer_id: 1,
          amount: 0,
          emission_date: Date.today
        )

        expect(invoice.valid?).to be false
        expect(invoice.errors).to include('Amount must be greater than 0')
      end
    end

    context 'when amount is negative' do
      it 'returns false and includes error message' do
        invoice = Domain::Entities::Invoice.new(
          customer_id: 1,
          amount: -500,
          emission_date: Date.today
        )

        expect(invoice.valid?).to be false
        expect(invoice.errors).to include('Amount must be greater than 0')
      end
    end

    context 'when emission_date is in the future' do
      it 'returns false and includes error message' do
        invoice = Domain::Entities::Invoice.new(
          customer_id: 1,
          amount: 1000,
          emission_date: Date.today + 1
        )

        expect(invoice.valid?).to be false
        expect(invoice.errors).to include('Emission date cannot be in the future')
      end
    end

    context 'when multiple validation errors exist' do
      it 'returns all error messages' do
        invoice = Domain::Entities::Invoice.new(
          customer_id: nil,
          amount: -100,
          emission_date: Date.today + 1
        )

        expect(invoice.valid?).to be false
        expect(invoice.errors.count).to eq(3)
      end
    end
  end

  describe '#amount_positive?' do
    it 'returns true when amount is greater than zero' do
      invoice = Domain::Entities::Invoice.new(amount: 100)
      expect(invoice.amount_positive?).to be true
    end

    it 'returns false when amount is zero' do
      invoice = Domain::Entities::Invoice.new(amount: 0)
      expect(invoice.amount_positive?).to be false
    end

    it 'returns false when amount is negative' do
      invoice = Domain::Entities::Invoice.new(amount: -50)
      expect(invoice.amount_positive?).to be false
    end

    it 'returns false when amount is nil' do
      invoice = Domain::Entities::Invoice.new(amount: nil)
      expect(invoice.amount_positive?).to be false
    end
  end

  describe '#emission_date_valid?' do
    it 'returns true when emission_date is today' do
      invoice = Domain::Entities::Invoice.new(emission_date: Date.today)
      expect(invoice.emission_date_valid?).to be true
    end

    it 'returns true when emission_date is in the past' do
      invoice = Domain::Entities::Invoice.new(emission_date: Date.today - 1)
      expect(invoice.emission_date_valid?).to be true
    end

    it 'returns false when emission_date is in the future' do
      invoice = Domain::Entities::Invoice.new(emission_date: Date.today + 1)
      expect(invoice.emission_date_valid?).to be false
    end

    it 'returns false when emission_date is nil' do
      invoice = Domain::Entities::Invoice.new(emission_date: nil)
      expect(invoice.emission_date_valid?).to be false
    end
  end

  describe '#calculate_tax' do
    it 'calculates 19% tax correctly' do
      invoice = Domain::Entities::Invoice.new(amount: 1000)
      expect(invoice.calculate_tax).to eq(190.0)
    end

    it 'rounds to 2 decimal places' do
      invoice = Domain::Entities::Invoice.new(amount: 1234.56)
      expect(invoice.calculate_tax).to eq(234.57)
    end
  end

  describe '#total_with_tax' do
    it 'calculates total including tax' do
      invoice = Domain::Entities::Invoice.new(amount: 1000)
      expect(invoice.total_with_tax).to eq(1190.0)
    end

    it 'rounds to 2 decimal places' do
      invoice = Domain::Entities::Invoice.new(amount: 100)
      expect(invoice.total_with_tax).to eq(119.0)
    end
  end

  describe '#cancellable?' do
    it 'returns true when status is pending' do
      invoice = Domain::Entities::Invoice.new(
        customer_id: 1,
        amount: 1000,
        status: 'pending'
      )
      expect(invoice.cancellable?).to be true
    end

    it 'returns true when status is issued' do
      invoice = Domain::Entities::Invoice.new(
        customer_id: 1,
        amount: 1000,
        status: 'issued'
      )
      expect(invoice.cancellable?).to be true
    end

    it 'returns false when status is cancelled' do
      invoice = Domain::Entities::Invoice.new(
        customer_id: 1,
        amount: 1000,
        status: 'cancelled'
      )
      expect(invoice.cancellable?).to be false
    end

    it 'returns false when status is completed' do
      invoice = Domain::Entities::Invoice.new(
        customer_id: 1,
        amount: 1000,
        status: 'completed'
      )
      expect(invoice.cancellable?).to be false
    end
  end

  describe '#to_h' do
    it 'converts invoice to hash with all attributes' do
      invoice = Domain::Entities::Invoice.new(
        id: 123,
        customer_id: 456,
        amount: 1000,
        emission_date: Date.new(2025, 10, 20),
        status: 'pending'
      )

      hash = invoice.to_h

      expect(hash[:id]).to eq(123)
      expect(hash[:customer_id]).to eq(456)
      expect(hash[:amount]).to eq(1000)
      expect(hash[:emission_date]).to eq(Date.new(2025, 10, 20))
      expect(hash[:status]).to eq('pending')
      expect(hash[:tax]).to eq(190.0)
      expect(hash[:total]).to eq(1190.0)
    end
  end
end
