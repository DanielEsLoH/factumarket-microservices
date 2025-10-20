# Auditoria Controller
# MVC Pattern - Controller layer
# Provides read-only access to audit events stored in MongoDB

class AuditoriaController < ApplicationController
  # GET /auditoria/:factura_id
  # Get all audit events related to a specific invoice
  def show
    factura_id = params[:id]

    events = AuditEvent.where(
      entity_type: 'Invoice',
      entity_id: factura_id
    ).order_by(timestamp: :desc)

    render json: {
      success: true,
      count: events.count,
      factura_id: factura_id,
      data: events.map { |e| event_response(e) }
    }, status: :ok
  rescue => e
    Rails.logger.error "Error fetching audit events: #{e.message}"
    render json: {
      success: false,
      message: 'Error interno del servidor',
      error: e.message
    }, status: :internal_server_error
  end

  # GET /auditoria
  # List all audit events with optional filters
  def index
    query = build_query

    events = AuditEvent.where(query).order_by(timestamp: :desc).limit(100)

    render json: {
      success: true,
      count: events.count,
      data: events.map { |e| event_response(e) }
    }, status: :ok
  rescue => e
    Rails.logger.error "Error listing audit events: #{e.message}"
    render json: {
      success: false,
      message: 'Error interno del servidor',
      error: e.message
    }, status: :internal_server_error
  end

  private

  def build_query
    query = {}

    query[:service] = params[:service] if params[:service].present?
    query[:entity_type] = params[:entity_type] if params[:entity_type].present?
    query[:event_type] = params[:event_type] if params[:event_type].present?

    if params[:fecha_inicio].present? && params[:fecha_fin].present?
      query[:timestamp] = {
        '$gte' => Time.parse(params[:fecha_inicio]),
        '$lte' => Time.parse(params[:fecha_fin])
      }
    end

    query
  end

  def event_response(event)
    {
      id: event.id.to_s,
      event_type: event.event_type,
      service: event.service,
      entity_type: event.entity_type,
      entity_id: event.entity_id,
      timestamp: event.timestamp,
      http_method: event.http_method,
      endpoint: event.endpoint,
      metadata: event.metadata,
      created_at: event.created_at
    }
  end
end
