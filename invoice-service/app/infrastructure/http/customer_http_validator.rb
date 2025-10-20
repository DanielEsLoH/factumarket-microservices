# Infrastructure Layer - HTTP Customer Validator
# Implements CustomerValidator interface by calling Customer Service API
# Uses Faraday HTTP client

require 'faraday'

module Infrastructure
  module Http
    class CustomerHttpValidator < Application::Services::CustomerValidator
      def exists?(customer_id)
        return false if customer_id.nil?

        customer_service_url = ENV.fetch('CUSTOMER_SERVICE_URL', 'http://localhost:3001')

        response = Faraday.get("#{customer_service_url}/clientes/#{customer_id}")

        if response.status == 200
          body = JSON.parse(response.body)
          body['success'] == true
        else
          false
        end
      rescue Faraday::Error, JSON::ParserError => e
        Rails.logger.error "Error validating customer: #{e.message}"
        false
      end
    end
  end
end
