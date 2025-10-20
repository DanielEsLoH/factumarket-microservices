# 🧪 Manual Testing Guide - FactuMarket Microservices

## Pre-requisitos

Antes de comenzar las pruebas, asegúrate de tener instalado:
- Docker y Docker Compose
- curl (viene instalado en macOS/Linux)
- jq (opcional, para formatear JSON): `brew install jq` en macOS

## Paso 1: Levantar el Sistema (IMPORTANTE)

### 1.1 Navegar al directorio del proyecto

```bash
cd "/Users/daniel.eslo/Desktop/Code/FactuMarket S.A./factumarket-microservices"
```

### 1.2 Verificar que los archivos están presentes

```bash
ls -la
# Deberías ver:
# - docker-compose.yml
# - customer-service/
# - invoice-service/
# - audit-service/
# - README.md
# - QUICK_START.md
```

### 1.3 Iniciar todos los servicios

```bash
docker-compose up -d --build
```

**Nota**: La primera vez tardará 5-10 minutos descargando las imágenes de PostgreSQL, MongoDB y RabbitMQ.

### 1.4 Monitorear los logs

En otra terminal, ejecuta:
```bash
docker-compose logs -f
```

Espera a ver estos mensajes:
```
factumarket-customer-service | => Booting Puma
factumarket-customer-service | * Listening on http://0.0.0.0:3000
factumarket-invoice-service | => Booting Puma
factumarket-invoice-service | * Listening on http://0.0.0.0:3000
factumarket-audit-service | => Booting Puma
factumarket-audit-service | * Listening on http://0.0.0.0:3000
```

### 1.5 Verificar que todos los contenedores están corriendo

```bash
docker ps
```

Deberías ver 6 contenedores activos:
- factumarket-customer-service
- factumarket-invoice-service
- factumarket-audit-service
- factumarket-postgres
- factumarket-mongodb
- factumarket-rabbitmq

---

## Paso 2: Verificar Health Checks

### 2.1 Customer Service

```bash
curl http://localhost:3001/up
```

**Resultado esperado**:
```
200 OK
```

### 2.2 Invoice Service

```bash
curl http://localhost:3002/up
```

**Resultado esperado**:
```
200 OK
```

### 2.3 Audit Service

```bash
curl http://localhost:3003/up
```

**Resultado esperado**:
```
200 OK
```

### 2.4 RabbitMQ Management UI

Abre en tu navegador:
```
http://localhost:15672
```

Credenciales:
- Usuario: `guest`
- Password: `guest`

**Verifica**:
- Ir a "Exchanges" → Deberías ver `factumarket_events`
- Ir a "Queues" → Deberías ver `audit_service_queue`

---

## Paso 3: Crear las Bases de Datos y Ejecutar Migraciones

### 3.1 Customer Service

```bash
docker exec factumarket-customer-service rails db:create
docker exec factumarket-customer-service rails db:migrate
```

**Resultado esperado**:
```
Created database 'customers'
== 20251020000001 CreateCustomers: migrating ==================================
== 20251020000001 CreateCustomers: migrated (0.0234s) =========================
```

### 3.2 Invoice Service

```bash
docker exec factumarket-invoice-service rails db:create
docker exec factumarket-invoice-service rails db:migrate
```

**Resultado esperado**:
```
Created database 'invoices'
== 20251020000001 CreateInvoices: migrating ===================================
== 20251020000001 CreateInvoices: migrated (0.0198s) ==========================
```

### 3.3 Cargar Datos de Prueba (Seed)

```bash
docker exec factumarket-customer-service rails db:seed
```

**Resultado esperado**:
```
🌱 Seeding Customer Service...
✅ Created customer: Empresa ABC S.A.S (ID: 1)
✅ Created customer: Comercial XYZ Ltda (ID: 2)
✅ Created customer: Distribuidora Nacional S.A (ID: 3)
✅ Created customer: Juan Pérez Gómez (ID: 4)
✅ Created customer: María Rodríguez López (ID: 5)

✨ Customer Service seeding completed!
📊 Total customers: 5
```

---

## Paso 4: Generar Token JWT

### Opción A: Usando Ruby directamente

```bash
ruby -e "require 'jwt'; puts JWT.encode({user_id: 1, email: 'admin@factumarket.com', exp: (Time.now + 86400).to_i}, 'factumarket_secret_key_2025', 'HS256')"
```

### Opción B: Usando Docker

```bash
docker exec factumarket-customer-service rails runner "require 'jwt'; puts JWT.encode({user_id: 1, email: 'admin@factumarket.com', exp: (Time.now + 86400).to_i}, 'factumarket_secret_key_2025', 'HS256')"
```

**Copia el token generado** y guárdalo en una variable:

```bash
export TOKEN="<pega-aqui-el-token-generado>"
```

Para verificar que se guardó correctamente:
```bash
echo $TOKEN
```

---

## Paso 5: Probar Customer Service

### Test 5.1: Listar Todos los Clientes (GET /clientes)

```bash
curl -X GET http://localhost:3001/clientes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq
```

**Resultado esperado**:
```json
{
  "success": true,
  "count": 5,
  "data": [
    {
      "id": 1,
      "name": "Empresa ABC S.A.S",
      "identification": "901234567-8",
      "email": "contacto@empresaabc.com",
      "address": "Calle 123 #45-67, Bogotá, Colombia",
      "created_at": "...",
      "updated_at": "..."
    },
    ...
  ]
}
```

✅ **Verificar**: `success: true`, `count: 5`, 5 clientes en `data`

### Test 5.2: Obtener Cliente Específico (GET /clientes/:id)

```bash
curl -X GET http://localhost:3001/clientes/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq
```

**Resultado esperado**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Empresa ABC S.A.S",
    "identification": "901234567-8",
    "email": "contacto@empresaabc.com",
    "address": "Calle 123 #45-67, Bogotá, Colombia"
  }
}
```

✅ **Verificar**: Cliente ID 1 retornado correctamente

### Test 5.3: Crear Nuevo Cliente (POST /clientes)

```bash
curl -X POST http://localhost:3001/clientes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "name": "TechCorp Solutions S.A.S",
      "identification": "900555666-7",
      "email": "contact@techcorp.com",
      "address": "Avenida El Dorado #50-25, Bogotá"
    }
  }' | jq
```

**Resultado esperado**:
```json
{
  "success": true,
  "message": "Cliente registrado exitosamente",
  "data": {
    "id": 6,
    "name": "TechCorp Solutions S.A.S",
    "identification": "900555666-7",
    "email": "contact@techcorp.com",
    "address": "Avenida El Dorado #50-25, Bogotá",
    "created_at": "...",
    "updated_at": "..."
  }
}
```

✅ **Verificar**: `success: true`, nuevo cliente con ID 6 creado

### Test 5.4: Verificar Validaciones - Cliente Duplicado

```bash
curl -X POST http://localhost:3001/clientes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "name": "TechCorp Solutions S.A.S",
      "identification": "900555666-7",
      "email": "contact@techcorp.com",
      "address": "Avenida El Dorado #50-25, Bogotá"
    }
  }' | jq
```

**Resultado esperado**:
```json
{
  "success": false,
  "message": "Error al registrar cliente",
  "errors": [
    "Identification has already been taken",
    "Email has already been taken"
  ]
}
```

✅ **Verificar**: `success: false`, errores de validación presentes

### Test 5.5: Probar Sin Token JWT (Debería Fallar)

```bash
curl -X GET http://localhost:3001/clientes
```

**Resultado esperado**:
```json
{
  "success": false,
  "message": "Token de autenticación requerido"
}
```

✅ **Verificar**: Error 401 Unauthorized

---

## Paso 6: Probar Invoice Service (Clean Architecture)

### Test 6.1: Crear Factura Válida (POST /facturas)

```bash
curl -X POST http://localhost:3002/facturas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invoice": {
      "customer_id": 1,
      "amount": 1500000.50,
      "emission_date": "2025-10-20"
    }
  }' | jq
```

**Resultado esperado**:
```json
{
  "success": true,
  "message": "Factura creada exitosamente",
  "data": {
    "id": 1,
    "customer_id": 1,
    "amount": 1500000.5,
    "emission_date": "2025-10-20",
    "status": "pending",
    "tax": 285000.1,
    "total": 1785000.6,
    "created_at": "...",
    "updated_at": "..."
  }
}
```

✅ **Verificar**:
- `success: true`
- `tax: 285000.1` (19% de 1500000.5)
- `total: 1785000.6` (amount + tax)

### Test 6.2: Validación - Cliente No Existe (Comunicación entre Microservicios)

```bash
curl -X POST http://localhost:3002/facturas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invoice": {
      "customer_id": 9999,
      "amount": 1000000,
      "emission_date": "2025-10-20"
    }
  }' | jq
```

**Resultado esperado**:
```json
{
  "success": false,
  "data": null,
  "message": "Cliente no encontrado o inválido"
}
```

✅ **Verificar**:
- `success: false`
- Mensaje de error indicando cliente no válido
- **IMPORTANTE**: Esto demuestra que Invoice Service llama a Customer Service (comunicación entre microservicios)

### Test 6.3: Validación - Monto Negativo (Regla de Negocio)

```bash
curl -X POST http://localhost:3002/facturas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invoice": {
      "customer_id": 1,
      "amount": -500,
      "emission_date": "2025-10-20"
    }
  }' | jq
```

**Resultado esperado**:
```json
{
  "success": false,
  "data": null,
  "message": "Amount must be greater than 0"
}
```

✅ **Verificar**: Validación de dominio funciona (Clean Architecture - Domain Layer)

### Test 6.4: Validación - Fecha Futura (Regla de Negocio)

```bash
curl -X POST http://localhost:3002/facturas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invoice": {
      "customer_id": 1,
      "amount": 1000000,
      "emission_date": "2026-12-31"
    }
  }' | jq
```

**Resultado esperado**:
```json
{
  "success": false,
  "data": null,
  "message": "Emission date cannot be in the future"
}
```

✅ **Verificar**: Validación de fecha funciona

### Test 6.5: Crear Más Facturas para Pruebas

```bash
# Factura 2
curl -X POST http://localhost:3002/facturas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invoice": {
      "customer_id": 2,
      "amount": 2500000,
      "emission_date": "2025-10-19"
    }
  }' | jq

# Factura 3
curl -X POST http://localhost:3002/facturas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invoice": {
      "customer_id": 3,
      "amount": 750000,
      "emission_date": "2025-10-18"
    }
  }' | jq
```

### Test 6.6: Obtener Factura por ID (GET /facturas/:id)

```bash
curl -X GET http://localhost:3002/facturas/1 \
  -H "Authorization: Bearer $TOKEN" | jq
```

**Resultado esperado**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "customer_id": 1,
    "amount": 1500000.5,
    "tax": 285000.1,
    "total": 1785000.6,
    ...
  }
}
```

### Test 6.7: Listar Facturas por Rango de Fechas (GET /facturas?fechaInicio=XX&fechaFin=YY)

```bash
curl -X GET "http://localhost:3002/facturas?fechaInicio=2025-10-18&fechaFin=2025-10-20" \
  -H "Authorization: Bearer $TOKEN" | jq
```

**Resultado esperado**:
```json
{
  "success": true,
  "count": 3,
  "data": [
    { "id": 1, ... },
    { "id": 2, ... },
    { "id": 3, ... }
  ]
}
```

✅ **Verificar**: 3 facturas retornadas dentro del rango de fechas

---

## Paso 7: Probar Audit Service (MongoDB + RabbitMQ)

### Test 7.1: Esperar a que los Eventos se Procesen

**Espera 5-10 segundos** para que RabbitMQ procese y el Audit Service almacene los eventos.

Puedes verificar los logs:
```bash
docker-compose logs audit-service | grep "Event stored successfully"
```

Deberías ver múltiples líneas:
```
Event stored successfully: customer.created
Event stored successfully: invoice.created
...
```

### Test 7.2: Ver Todos los Eventos de Auditoría (GET /auditoria)

```bash
curl -X GET http://localhost:3003/auditoria \
  -H "Authorization: Bearer $TOKEN" | jq
```

**Resultado esperado**:
```json
{
  "success": true,
  "count": 15,
  "data": [
    {
      "id": "...",
      "event_type": "invoice.created",
      "service": "invoice_service",
      "entity_type": "Invoice",
      "entity_id": 1,
      "timestamp": "2025-10-20T...",
      "http_method": "POST",
      "endpoint": "/facturas",
      "metadata": {
        "id": 1,
        "customer_id": 1,
        "amount": 1500000.5,
        ...
      },
      "created_at": "..."
    },
    ...
  ]
}
```

✅ **Verificar**: Múltiples eventos almacenados (customer.created, invoice.created, customer.fetched, etc.)

### Test 7.3: Filtrar Eventos por Tipo de Entidad

```bash
# Solo eventos de Invoice
curl -X GET "http://localhost:3003/auditoria?entity_type=Invoice" \
  -H "Authorization: Bearer $TOKEN" | jq

# Solo eventos de Customer
curl -X GET "http://localhost:3003/auditoria?entity_type=Customer" \
  -H "Authorization: Bearer $TOKEN" | jq
```

### Test 7.4: Filtrar Eventos por Servicio

```bash
curl -X GET "http://localhost:3003/auditoria?service=invoice_service" \
  -H "Authorization: Bearer $TOKEN" | jq
```

### Test 7.5: Obtener Auditoría de una Factura Específica (GET /auditoria/:id)

```bash
curl -X GET http://localhost:3003/auditoria/1 \
  -H "Authorization: Bearer $TOKEN" | jq
```

**Resultado esperado**:
```json
{
  "success": true,
  "count": 2,
  "factura_id": "1",
  "data": [
    {
      "event_type": "invoice.created",
      "entity_id": 1,
      ...
    },
    {
      "event_type": "invoice.fetched",
      "entity_id": 1,
      ...
    }
  ]
}
```

✅ **Verificar**: Eventos relacionados a la factura ID 1

---

## Paso 8: Verificar Bases de Datos Directamente

### Test 8.1: Verificar Oracle Database (Customers)

```bash
docker exec -it factumarket-oracle sqlplus system/oracle@//localhost:1521/XEPDB1 <<EOF
SELECT COUNT(*) AS total_customers FROM customers;
SELECT id, name, identification FROM customers WHERE ROWNUM <= 5;
EXIT;
EOF
```

**Resultado esperado**:
```
TOTAL_CUSTOMERS
---------------
              6

ID  NAME                           IDENTIFICATION
--- ------------------------------ ---------------
1   Empresa ABC S.A.S              901234567-8
2   Comercial XYZ Ltda             800987654-1
...
```

### Test 8.2: Verificar Oracle Database (Invoices)

```bash
docker exec -it factumarket-oracle sqlplus system/oracle@//localhost:1521/XEPDB1 <<EOF
SELECT COUNT(*) AS total_invoices FROM invoices;
SELECT id, customer_id, amount, status FROM invoices;
EXIT;
EOF
```

**Resultado esperado**:
```
TOTAL_INVOICES
--------------
             3

ID  CUSTOMER_ID     AMOUNT  STATUS
--- ----------- ----------  --------
1             1  1500000.5  pending
2             2  2500000    pending
3             3  750000     pending
```

### Test 8.3: Verificar MongoDB (Audit Events)

```bash
docker exec -it factumarket-mongodb mongosh factumarket_audit_development --eval "db.audit_events.countDocuments()"
```

**Resultado esperado**:
```
15
```

```bash
docker exec -it factumarket-mongodb mongosh factumarket_audit_development --eval "db.audit_events.find({event_type: 'invoice.created'}).pretty()"
```

**Resultado esperado**: JSON con todos los eventos de tipo `invoice.created`

---

## Paso 9: Verificar RabbitMQ

### Test 9.1: Verificar Exchange y Queues

1. Abre http://localhost:15672
2. Login con `guest` / `guest`
3. Ve a **Exchanges**
4. Busca `factumarket_events`
5. ✅ **Verificar**: Exchange existe y es de tipo `topic`

6. Ve a **Queues**
7. Busca `audit_service_queue`
8. ✅ **Verificar**: Queue existe y tiene bindings a `customer.*` e `invoice.*`

### Test 9.2: Crear un Evento y Ver en RabbitMQ en Tiempo Real

En una ventana, deja abierto RabbitMQ UI en la página de Queues.

En otra terminal, crea un cliente nuevo:
```bash
curl -X POST http://localhost:3001/clientes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "name": "Test Real-Time",
      "identification": "999888777-6",
      "email": "test@realtime.com",
      "address": "Test Address 123"
    }
  }' | jq
```

Observa en RabbitMQ UI:
- El mensaje pasa por la queue `audit_service_queue`
- El contador "Total" se incrementa
- El mensaje es consumido por Audit Service

---

## Paso 10: Ejecutar Tests Unitarios

```bash
# Ejecutar tests del Invoice Service (Clean Architecture)
docker exec factumarket-invoice-service bundle exec rspec
```

**Resultado esperado**:
```
Domain::Entities::Invoice
  #valid?
    when invoice has valid data
      ✓ returns true
    when customer_id is nil
      ✓ returns false and includes error message
    when amount is zero
      ✓ returns false and includes error message
    when amount is negative
      ✓ returns false and includes error message
    when emission_date is in the future
      ✓ returns false and includes error message
    ...

Application::UseCases::CreateInvoice
  #execute
    when customer does not exist
      ✓ returns failure result with error message
    ...

Finished in 0.15 seconds (files took 2.5 seconds to load)
20 examples, 0 failures
```

✅ **Verificar**: Todos los tests pasan (0 failures)

---

## Checklist Final de Verificación

### ✅ Arquitectura y Patrones
- [ ] **Microservicios**: 3 servicios independientes funcionando
- [ ] **Clean Architecture**: Invoice Service con capas domain/application/infrastructure
- [ ] **MVC**: Controllers, Models, Routes correctamente implementados
- [ ] **Dependency Inversion**: Use cases reciben dependencias inyectadas

### ✅ Bases de Datos
- [ ] **Oracle**: Clientes y Facturas almacenadas
- [ ] **MongoDB**: Eventos de auditoría almacenados
- [ ] **Separación de Datos**: Transaccional (Oracle) vs Audit (NoSQL)

### ✅ Comunicación
- [ ] **Síncrona**: Invoice Service → Customer Service (HTTP)
- [ ] **Asíncrona**: Servicios → RabbitMQ → Audit Service
- [ ] **Eventos**: Publicados y consumidos correctamente

### ✅ Validaciones y Reglas de Negocio
- [ ] **Customer Validation**: Cliente debe existir antes de crear factura
- [ ] **Amount Validation**: Monto > 0
- [ ] **Date Validation**: Fecha no puede ser futura
- [ ] **Tax Calculation**: 19% IVA calculado correctamente

### ✅ Seguridad
- [ ] **JWT**: Todas las rutas protegidas
- [ ] **401 Unauthorized**: Sin token, acceso denegado

### ✅ Auditoría
- [ ] **Trazabilidad**: Todas las operaciones registradas
- [ ] **Consultas**: Auditoría por factura, por tipo, por servicio

### ✅ Testing
- [ ] **Unit Tests**: Tests de dominio pasan
- [ ] **Business Rules**: Validaciones de negocio funcionan

---

## Resumen de Comandos Útiles

```bash
# Ver logs en tiempo real
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f invoice-service

# Reiniciar un servicio
docker-compose restart invoice-service

# Detener todo
docker-compose down

# Detener y borrar volúmenes (reset completo)
docker-compose down -v

# Ver contenedores activos
docker ps

# Ejecutar comando en un contenedor
docker exec factumarket-invoice-service rails db:migrate

# Ver variables de entorno de un contenedor
docker exec factumarket-invoice-service env
```

---

## ¿Qué Demuestra Este Sistema?

1. ✅ **Arquitectura de Microservicios** - Servicios independientes, escalables
2. ✅ **Clean Architecture** - Separación de capas, lógica de negocio independiente
3. ✅ **Event-Driven Architecture** - Comunicación asíncrona desacoplada
4. ✅ **Polyglot Persistence** - Oracle (relacional) + MongoDB (NoSQL)
5. ✅ **Domain-Driven Design** - Entidades de dominio con reglas de negocio
6. ✅ **SOLID Principles** - Dependency Inversion, Single Responsibility
7. ✅ **API Security** - JWT authentication
8. ✅ **Testability** - Unit tests de lógica de dominio
9. ✅ **Observability** - Auditoría completa de operaciones
10. ✅ **DevOps** - Containerización, orquestación con Docker

---

¡Todo listo para demostrar! 🚀
