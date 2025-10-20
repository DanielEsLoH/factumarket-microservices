# config/initializers/clean_architecture.rb
# Manually require Clean Architecture files since Zeitwerk has issues with nested modules

# Require domain layer
require Rails.root.join('app/domain/entities/invoice.rb')
require Rails.root.join('app/domain/repositories/invoice_repository.rb')

# Require application layer
require Rails.root.join('app/application/services/customer_validator.rb')
require Rails.root.join('app/application/use_cases/create_invoice.rb')
require Rails.root.join('app/application/use_cases/get_invoice.rb')
require Rails.root.join('app/application/use_cases/list_invoices.rb')

# Require infrastructure layer
require Rails.root.join('app/infrastructure/persistence/oracle_invoice_repository.rb')
require Rails.root.join('app/infrastructure/http/customer_http_validator.rb')
require Rails.root.join('app/infrastructure/messaging/rabbitmq_event_publisher.rb')
