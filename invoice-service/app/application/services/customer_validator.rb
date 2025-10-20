# Application Layer - Customer Validator Service
# Interface for validating that a customer exists
# Implementation will be in Infrastructure layer

module Application
  module Services
    class CustomerValidator
      def exists?(customer_id)
        raise NotImplementedError, 'Subclass must implement exists? method'
      end
    end
  end
end
