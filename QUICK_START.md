# 🚀 Quick Start Guide - FactuMarket Microservices

## ⚡ Inicio Rápido (5 minutos)

### 1. Levantar el Sistema Completo

```bash
cd factumarket-microservices
docker-compose up --build
```

**Nota**: La primera vez puede tardar 5-10 minutos descargando imágenes de PostgreSQL, MongoDB y RabbitMQ.

### 2. Verificar que los Servicios Están Activos

```bash
# Customer Service
curl http://localhost:3001/up

# Invoice Service
curl http://localhost:3002/up

# Audit Service
curl http://localhost:3003/up
```

Deberías ver respuestas exitosas de cada servicio.

### 3. Generar Token JWT para Autenticación

```bash
# Opción 1: Usando Ruby
ruby -e "require 'jwt'; puts JWT.encode({user_id: 1, email: 'admin@factumarket.com'}, 'factumarket_secret_key_2025', 'HS256')"

# Opción 2: Usando IRB
irb
require 'jwt'
token = JWT.encode({user_id: 1, email: 'admin@factumarket.com'}, 'factumarket_secret_key_2025', 'HS256')
puts token
exit
```

Guarda el token generado, lo necesitarás para todas las peticiones.

### 4. Cargar Datos de Prueba

```bash
# Crear clientes de ejemplo
docker exec factumarket-customer-service rails db:seed

# Deberías ver:
# ✅ Created customer: Empresa ABC S.A.S (ID: 1)
# ✅ Created customer: Comercial XYZ Ltda (ID: 2)
# ...
```

### 5. Probar el Flujo Completo

#### A. Listar Clientes

```bash
export TOKEN="<tu-token-jwt-aqui>"

curl -X GET http://localhost:3001/clientes \
  -H "Authorization: Bearer $TOKEN"
```

#### B. Crear una Factura

```bash
curl -X POST http://localhost:3002/facturas \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "invoice": {
      "customer_id": 1,
      "amount": 1500000.50,
      "emission_date": "2025-10-20"
    }
  }'
```

#### C. Ver los Eventos de Auditoría

```bash
# Auditoría de la factura creada
curl -X GET http://localhost:3003/auditoria/1 \
  -H "Authorization: Bearer $TOKEN"
```

### 6. Verificar RabbitMQ Management UI

Abre en tu navegador:
```
http://localhost:15672
```

**Credenciales**:
- Usuario: `guest`
- Password: `guest`

Deberías ver:
- Exchange: `factumarket_events`
- Queue: `audit_service_queue`
- Eventos pasando entre servicios

## 📊 Ejemplos de Uso Completo

### Escenario 1: Crear Cliente y Factura

```bash
# 1. Crear un nuevo cliente
curl -X POST http://localhost:3001/clientes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "customer": {
      "name": "TechSolutions S.A.S",
      "identification": "900111222-3",
      "email": "info@techsolutions.com",
      "address": "Calle 100 #15-20, Bogotá"
    }
  }'

# Respuesta (guarda el ID):
# {
#   "success": true,
#   "message": "Cliente registrado exitosamente",
#   "data": {
#     "id": 6,
#     ...
#   }
# }

# 2. Crear factura para ese cliente
curl -X POST http://localhost:3002/facturas \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "invoice": {
      "customer_id": 6,
      "amount": 2500000,
      "emission_date": "2025-10-20"
    }
  }'

# Respuesta:
# {
#   "success": true,
#   "message": "Factura creada exitosamente",
#   "data": {
#     "id": 1,
#     "customer_id": 6,
#     "amount": 2500000.0,
#     "tax": 475000.0,
#     "total": 2975000.0,
#     ...
#   }
# }

# 3. Verificar auditoría de ambas operaciones
curl -X GET "http://localhost:3003/auditoria?entity_type=Customer" \
  -H "Authorization: Bearer $TOKEN"

curl -X GET "http://localhost:3003/auditoria?entity_type=Invoice" \
  -H "Authorization: Bearer $TOKEN"
```

### Escenario 2: Consultar Facturas por Rango de Fechas

```bash
# Listar facturas de octubre 2025
curl -X GET "http://localhost:3002/facturas?fechaInicio=2025-10-01&fechaFin=2025-10-31" \
  -H "Authorization: Bearer $TOKEN"
```

### Escenario 3: Validación de Negocio - Factura Inválida

```bash
# Intentar crear factura con monto negativo
curl -X POST http://localhost:3002/facturas \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "invoice": {
      "customer_id": 1,
      "amount": -1000,
      "emission_date": "2025-10-20"
    }
  }'

# Respuesta:
# {
#   "success": false,
#   "message": "Amount must be greater than 0",
#   "data": null
# }

# Intentar crear factura para cliente inexistente
curl -X POST http://localhost:3002/facturas \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "invoice": {
      "customer_id": 9999,
      "amount": 1000,
      "emission_date": "2025-10-20"
    }
  }'

# Respuesta:
# {
#   "success": false,
#   "message": "Cliente no encontrado o inválido",
#   "data": null
# }
```

## 🧪 Ejecutar Tests

```bash
# Ejecutar tests unitarios del Invoice Service
docker exec factumarket-invoice-service bundle exec rspec

# Deberías ver:
# Domain::Entities::Invoice
#   #valid?
#     when invoice has valid data
#       ✓ returns true
#     when customer_id is nil
#       ✓ returns false and includes error message
#     ...
#
# Finished in 0.05 seconds
# 20 examples, 0 failures
```

## 🔍 Ver Logs

```bash
# Ver logs de todos los servicios
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f customer-service
docker-compose logs -f invoice-service
docker-compose logs -f audit-service

# Ver logs de bases de datos
docker-compose logs -f postgres
docker-compose logs -f mongodb
docker-compose logs -f rabbitmq
```

## 🛑 Detener los Servicios

```bash
# Detener todos los servicios
docker-compose down

# Detener y eliminar volúmenes (borra todos los datos)
docker-compose down -v
```

## 🔄 Reiniciar un Servicio Específico

```bash
# Reiniciar Customer Service
docker-compose restart customer-service

# Reconstruir y reiniciar Invoice Service
docker-compose up -d --build invoice-service
```

## 📝 Acceso a las Bases de Datos

### PostgreSQL Database

```bash
# Conectarse a PostgreSQL
docker exec -it factumarket-postgres psql -U postgres

# Ver bases de datos
\l

# Conectarse a base de datos de clientes
\c factumarket_customers_development

# Ver tablas
\dt

# Ver clientes
SELECT * FROM customers;

# Conectarse a base de datos de facturas
\c factumarket_invoices_development

# Ver facturas
SELECT * FROM invoices;

# Salir
\q
```

### MongoDB

```bash
# Conectarse a MongoDB
docker exec -it factumarket-mongodb mongosh

# Cambiar a la base de datos de auditoría
use factumarket_audit_development

# Ver todos los eventos de auditoría
db.audit_events.find().pretty()

# Ver eventos de tipo invoice.created
db.audit_events.find({event_type: "invoice.created"}).pretty()

# Contar eventos
db.audit_events.countDocuments()

# Salir
exit
```

## ⚠️ Troubleshooting

### Problema: PostgreSQL no se conecta

```bash
# Ver logs de PostgreSQL
docker-compose logs postgres

# Verificar que PostgreSQL está listo
docker exec -it factumarket-postgres pg_isready -U postgres

# Si no está listo, esperar unos segundos y reintentar
```

### Problema: Eventos no llegan a Audit Service

```bash
# Verificar que RabbitMQ esté corriendo
curl http://localhost:15672

# Verificar el Event Consumer
docker-compose logs audit-service | grep "Event Consumer"

# Deberías ver: "Event Consumer started. Waiting for messages..."
```

### Problema: "Token inválido o expirado"

```bash
# Generar un nuevo token JWT
ruby -e "require 'jwt'; puts JWT.encode({user_id: 1, email: 'admin@factumarket.com'}, 'factumarket_secret_key_2025', 'HS256')"
```

### Problema: Migración de base de datos falla

```bash
# Ejecutar manualmente
docker exec factumarket-customer-service rails db:create db:migrate
docker exec factumarket-invoice-service rails db:create db:migrate
```

## 📚 Siguiente Paso

Lee el `README.md` completo para entender:
- Arquitectura detallada del sistema
- Clean Architecture en el Invoice Service
- Patrones y principios aplicados
- Documentación completa de APIs

## 🎯 Puntos Clave a Demostrar

1. ✅ **Microservicios**: 3 servicios independientes (Customer, Invoice, Audit)
2. ✅ **Clean Architecture**: Invoice Service con capas domain/application/infrastructure
3. ✅ **MVC**: Controllers, Models siguiendo patrón MVC
4. ✅ **PostgreSQL**: Clientes y Facturas en PostgreSQL (transaccional)
5. ✅ **MongoDB**: Eventos de auditoría en NoSQL
6. ✅ **RabbitMQ**: Comunicación asíncrona entre servicios
7. ✅ **JWT**: Autenticación en todos los endpoints
8. ✅ **Tests**: RSpec tests para lógica de dominio
9. ✅ **Docker**: Todo containerizado y orquestado
10. ✅ **Auditoría**: Trazabilidad completa de todas las operaciones

¡Disfruta explorando el sistema! 🚀
