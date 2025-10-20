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

        # Generate a service token for inter-service communication
        service_token = generate_service_token

        response = Faraday.get("#{customer_service_url}/clientes/#{customer_id}") do |req|
          req.headers['Authorization'] = "Bearer #{service_token}"
        end

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

      private

      def generate_service_token
        # Generate a service-to-service JWT token
        require 'jwt'
        payload = {
          user_id: 0,  # Service account
          service: 'invoice_service',
          purpose: 'customer_validation',
          exp: (Time.now + 60).to_i  # 1 minute expiration
        }
        JWT.encode(payload, ENV.fetch('JWT_SECRET_KEY', 'factumarket_secret_key_2025'), 'HS256')
      end
    end
  end
end
