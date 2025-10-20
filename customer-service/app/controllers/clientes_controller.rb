# CustomersController (Clientes)
# MVC Pattern - Controller layer
# Handles HTTP requests for customer management

class ClientesController < ApplicationController
  before_action :set_customer, only: [:show]

  # POST /clientes
  # Register a new customer
  def create
    customer = Customer.new(customer_params)

    if customer.save
      render json: {
        success: true,
        message: 'Cliente registrado exitosamente',
        data: customer_response(customer)
      }, status: :created
    else
      render json: {
        success: false,
        message: 'Error al registrar cliente',
        errors: customer.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Error creating customer: #{e.message}"
    render json: {
      success: false,
      message: 'Error interno del servidor',
      error: e.message
    }, status: :internal_server_error
  end

  # GET /clientes/:id
  # Get customer by ID
  def show
    render json: {
      success: true,
      data: customer_response(@customer)
    }, status: :ok
  rescue => e
    Rails.logger.error "Error fetching customer: #{e.message}"
    render json: {
      success: false,
      message: 'Error interno del servidor',
      error: e.message
    }, status: :internal_server_error
  end

  # GET /clientes
  # List all customers
  def index
    customers = Customer.all.order(created_at: :desc)

    # Publish event for listing
    EventPublisher.publish('customer.listed', { count: customers.count })

    render json: {
      success: true,
      count: customers.count,
      data: customers.map { |c| customer_response(c) }
    }, status: :ok
  rescue => e
    Rails.logger.error "Error listing customers: #{e.message}"
    render json: {
      success: false,
      message: 'Error interno del servidor',
      error: e.message
    }, status: :internal_server_error
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: 'Cliente no encontrado'
    }, status: :not_found
  end

  def customer_params
    params.require(:customer).permit(:name, :identification, :email, :address)
  end

  def customer_response(customer)
    {
      id: customer.id,
      name: customer.name,
      identification: customer.identification,
      email: customer.email,
      address: customer.address,
      created_at: customer.created_at,
      updated_at: customer.updated_at
    }
  end
end
