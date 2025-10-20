# Event Consumer for RabbitMQ
# Consumes events from RabbitMQ and stores them in MongoDB for audit

require 'bunny'
require 'json'

class EventConsumer
  EXCHANGE_NAME = 'factumarket_events'
  QUEUE_NAME = 'audit_service_queue'

  def self.start
    connection = Bunny.new(
      host: ENV.fetch('RABBITMQ_HOST', 'localhost'),
      port: ENV.fetch('RABBITMQ_PORT', '5672'),
      user: ENV.fetch('RABBITMQ_USER', 'guest'),
      password: ENV.fetch('RABBITMQ_PASSWORD', 'guest')
    )

    connection.start
    channel = connection.create_channel
    exchange = channel.topic(EXCHANGE_NAME, durable: true)
    queue = channel.queue(QUEUE_NAME, durable: true)

    # Bind to all events (customer.* and invoice.*)
    queue.bind(exchange, routing_key: 'customer.*')
    queue.bind(exchange, routing_key: 'invoice.*')

    Rails.logger.info "Event Consumer started. Waiting for messages..."

    queue.subscribe(block: true, manual_ack: true) do |delivery_info, properties, body|
      begin
        message = JSON.parse(body)
        Rails.logger.info "Received event: #{message['event_type']}"

        # Store in MongoDB via AuditEvent model
        AuditEvent.create!(
          event_type: message['event_type'],
          service: message['service'],
          entity_type: extract_entity_type(message['event_type']),
          entity_id: message['payload']['id'],
          timestamp: message['timestamp'],
          metadata: message['payload'],
          http_method: infer_http_method(message['event_type']),
          endpoint: infer_endpoint(message['event_type'], message['payload'])
        )

        channel.ack(delivery_info.delivery_tag)
        Rails.logger.info "Event stored successfully: #{message['event_type']}"
      rescue => e
        Rails.logger.error "Error processing event: #{e.message}"
        channel.nack(delivery_info.delivery_tag, false, true)
      end
    end
  rescue Interrupt => _
    connection.close if connection
    Rails.logger.info "Event Consumer stopped"
  end

  private

  def self.extract_entity_type(event_type)
    # e.g., "customer.created" => "Customer"
    event_type.split('.').first.capitalize
  end

  def self.infer_http_method(event_type)
    case event_type.split('.').last
    when 'created' then 'POST'
    when 'fetched', 'listed' then 'GET'
    when 'updated' then 'PUT'
    when 'deleted' then 'DELETE'
    else 'UNKNOWN'
    end
  end

  def self.infer_endpoint(event_type, payload)
    entity = event_type.split('.').first
    action = event_type.split('.').last

    if action == 'created' || action == 'listed'
      "/#{entity}s"
    else
      "/#{entity}s/#{payload['id']}"
    end
  end
end
