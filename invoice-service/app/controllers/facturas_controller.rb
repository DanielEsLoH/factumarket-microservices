# Interface Adapters Layer - Facturas Controller
# MVC Pattern - Controller
# Orchestrates use cases with dependency injection (Clean Architecture)

class FacturasController < ApplicationController
  # POST /facturas
  # Create a new invoice
  def create
    use_case = build_create_invoice_use_case

    result = use_case.execute(
      customer_id: invoice_params[:customer_id],
      amount: invoice_params[:amount],
      emission_date: invoice_params[:emission_date]
    )

    if result[:success]
      render json: result, status: :created
    else
      render json: result, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Error in create action: #{e.message}"
    render json: {
      success: false,
      message: 'Error interno del servidor',
      error: e.message
    }, status: :internal_server_error
  end

  # GET /facturas/:id
  # Get invoice by ID
  def show
    use_case = build_get_invoice_use_case

    result = use_case.execute(params[:id])

    if result[:success]
      render json: result, status: :ok
    else
      render json: result, status: :not_found
    end
  rescue => e
    Rails.logger.error "Error in show action: #{e.message}"
    render json: {
      success: false,
      message: 'Error interno del servidor',
      error: e.message
    }, status: :internal_server_error
  end

  # GET /facturas
  # List invoices with optional date range filter
  def index
    use_case = build_list_invoices_use_case

    filters = {
      fecha_inicio: params[:fechaInicio],
      fecha_fin: params[:fechaFin]
    }.compact

    result = use_case.execute(filters)

    render json: result, status: :ok
  rescue => e
    Rails.logger.error "Error in index action: #{e.message}"
    render json: {
      success: false,
      message: 'Error interno del servidor',
      error: e.message
    }, status: :internal_server_error
  end

  private

  def invoice_params
    params.require(:invoice).permit(:customer_id, :amount, :emission_date)
  end

  # Dependency Injection: Build use case with all dependencies
  def build_create_invoice_use_case
    Application::UseCases::CreateInvoice.new(
      invoice_repository: Infrastructure::Persistence::OracleInvoiceRepository.new,
      customer_validator: Infrastructure::Http::CustomerHttpValidator.new,
      event_publisher: Infrastructure::Messaging::RabbitmqEventPublisher.new
    )
  end

  def build_get_invoice_use_case
    Application::UseCases::GetInvoice.new(
      invoice_repository: Infrastructure::Persistence::OracleInvoiceRepository.new,
      event_publisher: Infrastructure::Messaging::RabbitmqEventPublisher.new
    )
  end

  def build_list_invoices_use_case
    Application::UseCases::ListInvoices.new(
      invoice_repository: Infrastructure::Persistence::OracleInvoiceRepository.new,
      event_publisher: Infrastructure::Messaging::RabbitmqEventPublisher.new
    )
  end
end
