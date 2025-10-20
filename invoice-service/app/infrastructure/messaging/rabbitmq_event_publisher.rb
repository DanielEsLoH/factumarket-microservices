# Infrastructure Layer - RabbitMQ Event Publisher
# Implements event publishing interface

require 'bunny'
require 'json'

module Infrastructure
  module Messaging
    class RabbitmqEventPublisher
      EXCHANGE_NAME = 'factumarket_events'

      def publish(event_type, payload)
        connection = Bunny.new(
          host: ENV.fetch('RABBITMQ_HOST', 'localhost'),
          port: ENV.fetch('RABBITMQ_PORT', '5672'),
          user: ENV.fetch('RABBITMQ_USER', 'guest'),
          password: ENV.fetch('RABBITMQ_PASSWORD', 'guest')
        )

        connection.start
        channel = connection.create_channel
        exchange = channel.topic(EXCHANGE_NAME, durable: true)

        message = {
          event_type: event_type,
          payload: payload,
          timestamp: Time.current.iso8601,
          service: 'invoice_service'
        }

        exchange.publish(
          message.to_json,
          routing_key: event_type,
          persistent: true,
          content_type: 'application/json'
        )

        Rails.logger.info "Published event: #{event_type} - #{payload.inspect}"
      ensure
        connection.close if connection && connection.open?
      end
    end
  end
end
