# config/initializers/zeitwerk.rb
# Configure Zeitwerk to properly load Clean Architecture directories

# Custom inflections for specific class names
Rails.autoloaders.main.inflector.inflect(
  "postgresql_invoice_repository" => "PostgresqlInvoiceRepository",
  "oracle_invoice_repository" => "OracleInvoiceRepository",
  "rabbitmq_event_publisher" => "RabbitmqEventPublisher"
)
