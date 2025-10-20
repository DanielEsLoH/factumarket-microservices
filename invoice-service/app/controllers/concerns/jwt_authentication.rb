# JWT Authentication Concern
# Shared authentication logic for securing API endpoints
# Can be included in ApplicationController or specific controllers

require 'jwt'

module JwtAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
  end

  private

  def authenticate_request
    header = request.headers['Authorization']

    if header.blank?
      render json: {
        success: false,
        message: 'Token de autenticación requerido'
      }, status: :unauthorized
      return
    end

    token = header.split(' ').last

    begin
      decoded = decode_token(token)
      @current_user = decoded
    rescue JWT::DecodeError => e
      render json: {
        success: false,
        message: 'Token inválido o expirado'
      }, status: :unauthorized
    end
  end

  def decode_token(token)
    secret_key = ENV.fetch('JWT_SECRET_KEY', 'factumarket_secret_key_2025')
    JWT.decode(token, secret_key, true, algorithm: 'HS256')[0]
  end

  def encode_token(payload)
    secret_key = ENV.fetch('JWT_SECRET_KEY', 'factumarket_secret_key_2025')
    exp = 24.hours.from_now.to_i
    payload[:exp] = exp
    JWT.encode(payload, secret_key, 'HS256')
  end
end
