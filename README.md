# FactuMarket S.A. - Sistema de Facturación Electrónica

Sistema completo de facturación electrónica basado en microservicios, construido con Ruby on Rails, implementando Clean Architecture, patrón MVC y arquitectura orientada a eventos.

> **Solución de Prueba Técnica** para la posición de Backend Developer en Double V Partners NYX

## 🚀 Inicio Rápido

```bash
# Clonar el repositorio
git clone <repository-url>
cd factumarket-microservices

# Iniciar todos los servicios con Docker
docker-compose up -d --build

# Esperar a que los servicios estén listos (2-3 minutos)
# Verificar que los 6 contenedores estén corriendo
docker ps

# ¡Listo! Visita los servicios:
# - Customer Service: http://localhost:3001
# - Invoice Service: http://localhost:3002
# - Audit Service: http://localhost:3003
# - RabbitMQ Management: http://localhost:15672 (guest/guest)
```

Para instrucciones detalladas de prueba, consulta [QUICK_START.md](QUICK_START.md) o [MANUAL_TESTING_GUIDE.md](MANUAL_TESTING_GUIDE.md).

## 📋 Tabla de Contenidos

- [Descripción del Proyecto](#descripción-del-proyecto)
- [Arquitectura](#arquitectura)
- [Tecnologías Utilizadas](#tecnologías-utilizadas)
- [Microservicios](#microservicios)
- [Requisitos Previos](#requisitos-previos)
- [Instalación y Configuración](#instalación-y-configuración)
- [Ejecución con Docker](#ejecución-con-docker)
- [API Endpoints](#api-endpoints)
- [Clean Architecture](#clean-architecture)
- [Pruebas](#pruebas)
- [Eventos de Auditoría](#eventos-de-auditoría)
- [Estructura del Repositorio](#estructura-del-repositorio)
- [Autor](#autor)

## 📖 Descripción del Proyecto

FactuMarket S.A. necesita modernizar su sistema de facturación electrónica. Este proyecto implementa una solución basada en microservicios que permite:

- ✅ Registro y gestión de clientes
- ✅ Emisión de facturas electrónicas con validaciones de negocio
- ✅ Almacenamiento transaccional en PostgreSQL
- ✅ Registro de eventos de auditoría en MongoDB (NoSQL)
- ✅ Comunicación asíncrona mediante RabbitMQ
- ✅ Autenticación con JWT
- ✅ Trazabilidad completa de operaciones

## 🏗️ Arquitectura

### Diagrama de Alto Nivel

```
┌─────────────────────────────────────────────────────────────┐
│                         CLIENTE                              │
└──────────────┬──────────────────────────────────────────────┘
               │ (HTTP/JSON + JWT)
               ▼
┌──────────────────────────────────────────────────────────────┐
│                    API GATEWAY (Opcional)                    │
│                  JWT Authentication Layer                     │
└───────┬──────────────────┬────────────────┬─────────────────┘
        │                  │                │
┌───────▼────────┐  ┌──────▼───────┐  ┌────▼─────────┐
│   Customer     │  │   Invoice    │  │    Audit     │
│   Service      │  │   Service    │  │   Service    │
│  (Rails API)   │  │  (Rails API) │  │  (Rails API) │
│   MVC Pattern  │  │ Clean Arch ✓ │  │  MVC Pattern │
└───────┬────────┘  └──────┬───────┘  └────┬─────────┘
        │                  │                │
┌───────▼────────┐  ┌──────▼───────┐  ┌────▼─────────┐
│  PostgreSQL    │  │  PostgreSQL  │  │  MongoDB     │
│  (customers)   │  │  (invoices)  │  │(audit_events)│
└────────────────┘  └──────────────┘  └──────────────┘
        │                  │                │
        └──────────────────┴────────────────┘
                           │
                  ┌────────▼────────┐
                  │   RabbitMQ      │
                  │  (Event Bus)    │
                  └─────────────────┘
```

### Comunicación entre Servicios

- **Síncrona (REST/HTTP)**: Invoice Service → Customer Service (validación de cliente)
- **Asíncrona (RabbitMQ)**: Todos los servicios publican eventos → Audit Service consume

### Bases de Datos

- **PostgreSQL**: Datos transaccionales (clientes y facturas)
- **MongoDB**: Logs de auditoría y eventos

## 🛠️ Tecnologías Utilizadas

| Componente | Tecnología |
|------------|------------|
| Framework | Ruby on Rails 8.0 (API mode) |
| Lenguaje | Ruby 3.2+ |
| DB Transaccional | PostgreSQL 16 (via pg adapter) |
| DB Auditoría | MongoDB 7.0 (via mongoid) |
| Message Queue | RabbitMQ 3.12 (via bunny) |
| Autenticación | JWT |
| HTTP Client | Faraday |
| Testing | RSpec |
| Containerización | Docker & Docker Compose |

## 🔬 Microservicios

### 1. Customer Service (Puerto 3001)

**Responsabilidad**: Gestión de clientes

**Endpoints**:
- `POST /clientes` - Registrar cliente
- `GET /clientes/:id` - Obtener cliente por ID
- `GET /clientes` - Listar clientes

**Base de Datos**: PostgreSQL (tabla `customers`)

**Arquitectura**: MVC tradicional

**Eventos Publicados**: `customer.created`, `customer.fetched`, `customer.listed`

### 2. Invoice Service (Puerto 3002)

**Responsabilidad**: Creación y gestión de facturas electrónicas

**Endpoints**:
- `POST /facturas` - Crear factura
- `GET /facturas/:id` - Obtener factura por ID
- `GET /facturas?fechaInicio=XX&fechaFin=YY` - Listar facturas por rango de fechas

**Base de Datos**: PostgreSQL (tabla `invoices`)

**Arquitectura**: **Clean Architecture** (ver sección detallada abajo)

**Validaciones de Negocio**:
- Cliente debe existir (consulta a Customer Service)
- Monto > 0
- Fecha de emisión válida (no futura)

**Eventos Publicados**: `invoice.created`, `invoice.fetched`, `invoice.listed`, `invoice.error`

### 3. Audit Service (Puerto 3003)

**Responsabilidad**: Registro y consulta de eventos de auditoría

**Endpoints**:
- `GET /auditoria/:factura_id` - Consultar eventos de una factura
- `GET /auditoria?service=XX&entity_type=YY` - Listar eventos con filtros

**Base de Datos**: MongoDB (colección `audit_events`)

**Arquitectura**: MVC + Event Consumer (RabbitMQ)

**Eventos Consumidos**: `customer.*`, `invoice.*`

## 📦 Requisitos Previos

- Docker 20.10+
- Docker Compose 1.29+
- (Opcional) Ruby 3.2+ si desea ejecutar localmente sin Docker

## 🚀 Instalación y Configuración

### Opción 1: Ejecución con Docker (Recomendado)

1. **Clonar el repositorio**:
```bash
git clone <repository-url>
cd factumarket-microservices
```

2. **Levantar todos los servicios con Docker Compose**:
```bash
docker-compose up --build
```

Esto iniciará:
- PostgreSQL (puerto 5432)
- MongoDB (puerto 27017)
- RabbitMQ (puerto 5672, Management UI: 15672)
- Customer Service (puerto 3001)
- Invoice Service (puerto 3002)
- Audit Service (puerto 3003)

3. **Esperar a que los servicios estén listos**:

Los servicios tienen health checks configurados. Espera a ver:
```
factumarket-customer-service | => Booting Puma
factumarket-invoice-service | => Booting Puma
factumarket-audit-service | => Booting Puma
```

4. **Verificar servicios**:
```bash
curl http://localhost:3001/up  # Customer Service
curl http://localhost:3002/up  # Invoice Service
curl http://localhost:3003/up  # Audit Service
```

### Opción 2: Ejecución Local (Sin Docker)

#### Prerrequisitos
- PostgreSQL instalado localmente o accesible
- MongoDB instalado
- RabbitMQ instalado

#### Pasos

1. **Configurar variables de entorno** para cada servicio:

Customer Service (`.env`):
```
POSTGRES_HOST=localhost
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
RABBITMQ_HOST=localhost
JWT_SECRET_KEY=factumarket_secret_key_2025
```

Invoice Service (`.env`):
```
POSTGRES_HOST=localhost
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
CUSTOMER_SERVICE_URL=http://localhost:3001
RABBITMQ_HOST=localhost
JWT_SECRET_KEY=factumarket_secret_key_2025
```

Audit Service (`.env`):
```
MONGODB_HOST=localhost
RABBITMQ_HOST=localhost
JWT_SECRET_KEY=factumarket_secret_key_2025
```

2. **Instalar dependencias y ejecutar migraciones**:

```bash
# Customer Service
cd customer-service
bundle install
rails db:create db:migrate
rails server -p 3001

# Invoice Service (nueva terminal)
cd invoice-service
bundle install
rails db:create db:migrate
rails server -p 3002

# Audit Service (nueva terminal)
cd audit-service
bundle install
rails server -p 3003

# Event Consumer (nueva terminal)
cd audit-service
rails runner 'EventConsumer.start'
```

## 📡 API Endpoints

### Autenticación

Todos los endpoints están protegidos con JWT. Para obtener un token (simplificado para la demo):

```bash
# Generar token JWT
irb
require 'jwt'
payload = { user_id: 1, email: 'admin@factumarket.com' }
secret = 'factumarket_secret_key_2025'
token = JWT.encode(payload, secret, 'HS256')
puts token
```

Incluir en todas las peticiones:
```
Authorization: Bearer <token>
```

### Customer Service

#### Registrar Cliente
```bash
curl -X POST http://localhost:3001/clientes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "customer": {
      "name": "Empresa ABC S.A.S",
      "identification": "901234567-8",
      "email": "contacto@empresaabc.com",
      "address": "Calle 123 #45-67, Bogotá"
    }
  }'
```

#### Obtener Cliente
```bash
curl -X GET http://localhost:3001/clientes/1 \
  -H "Authorization: Bearer <token>"
```

#### Listar Clientes
```bash
curl -X GET http://localhost:3001/clientes \
  -H "Authorization: Bearer <token>"
```

### Invoice Service

#### Crear Factura
```bash
curl -X POST http://localhost:3002/facturas \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "invoice": {
      "customer_id": 1,
      "amount": 1500000.50,
      "emission_date": "2025-10-20"
    }
  }'
```

#### Obtener Factura
```bash
curl -X GET http://localhost:3002/facturas/1 \
  -H "Authorization: Bearer <token>"
```

#### Listar Facturas por Rango de Fechas
```bash
curl -X GET "http://localhost:3002/facturas?fechaInicio=2025-10-01&fechaFin=2025-10-31" \
  -H "Authorization: Bearer <token>"
```

### Audit Service

#### Obtener Auditoría de una Factura
```bash
curl -X GET http://localhost:3003/auditoria/1 \
  -H "Authorization: Bearer <token>"
```

#### Listar Todos los Eventos de Auditoría
```bash
curl -X GET "http://localhost:3003/auditoria?service=invoice_service&entity_type=Invoice" \
  -H "Authorization: Bearer <token>"
```

## 🏛️ Clean Architecture

El **Invoice Service** implementa Clean Architecture completa con separación de capas:

### Estructura de Carpetas

```
invoice-service/
├── app/
│   ├── domain/                    # Capa de Dominio
│   │   ├── entities/
│   │   │   └── invoice.rb         # Entidad de dominio (lógica de negocio pura)
│   │   └── repositories/
│   │       └── invoice_repository.rb  # Interfaz del repositorio
│   ├── application/               # Capa de Aplicación
│   │   ├── use_cases/
│   │   │   ├── create_invoice.rb  # Caso de uso: Crear factura
│   │   │   ├── get_invoice.rb     # Caso de uso: Obtener factura
│   │   │   └── list_invoices.rb   # Caso de uso: Listar facturas
│   │   └── services/
│   │       └── customer_validator.rb  # Interfaz para validar cliente
│   ├── infrastructure/            # Capa de Infraestructura
│   │   ├── persistence/
│   │   │   └── postgresql_invoice_repository.rb  # Implementación PostgreSQL
│   │   ├── http/
│   │   │   └── customer_http_validator.rb    # Cliente HTTP
│   │   └── messaging/
│   │       └── rabbitmq_event_publisher.rb   # Publisher RabbitMQ
│   ├── controllers/               # Capa de Interface Adapters (MVC)
│   │   └── facturas_controller.rb # Controlador Rails
│   └── models/
│       └── invoice_model.rb       # ActiveRecord model (solo persistencia)
```

### Principios Aplicados

1. **Dependency Inversion**: Las capas internas (dominio) no dependen de las externas (infraestructura)
2. **Single Responsibility**: Cada clase tiene una única responsabilidad
3. **Separation of Concerns**: Lógica de negocio separada de frameworks y detalles de implementación
4. **Testability**: Lógica de dominio puede probarse sin Rails, DB o HTTP

### Flujo de Ejecución

```
HTTP Request
    ↓
FacturasController (Interface Adapters)
    ↓
CreateInvoice Use Case (Application Layer)
    ↓
Invoice Entity (Domain Layer) ← Validaciones de negocio
    ↓
PostgresqlInvoiceRepository (Infrastructure Layer)
    ↓
PostgreSQL Database
```

### Inversión de Dependencias

```ruby
# Domain define la interfaz
class InvoiceRepository
  def save(invoice_entity)
    raise NotImplementedError
  end
end

# Infrastructure implementa la interfaz
class PostgresqlInvoiceRepository < InvoiceRepository
  def save(invoice_entity)
    # Implementación con ActiveRecord
  end
end

# Use Case recibe la dependencia inyectada
class CreateInvoice
  def initialize(invoice_repository:)
    @invoice_repository = invoice_repository
  end
end
```

## 🧪 Pruebas

### Ejecutar Tests de Dominio (Invoice Service)

```bash
cd invoice-service
bundle exec rspec spec/domain/entities/invoice_spec.rb
bundle exec rspec spec/application/use_cases/create_invoice_spec.rb
```

### Cobertura de Tests

- ✅ Validación de monto positivo
- ✅ Validación de fecha de emisión
- ✅ Cálculo de impuestos (19% IVA)
- ✅ Reglas de negocio (factura cancelable)
- ✅ Flujo completo de creación de factura
- ✅ Manejo de errores

## 📊 Eventos de Auditoría

Cada operación en Customer Service e Invoice Service genera eventos que se almacenan en MongoDB:

### Estructura de Evento

```json
{
  "event_type": "invoice.created",
  "service": "invoice_service",
  "entity_type": "Invoice",
  "entity_id": 123,
  "timestamp": "2025-10-20T10:30:00Z",
  "http_method": "POST",
  "endpoint": "/facturas",
  "metadata": {
    "id": 123,
    "customer_id": 456,
    "amount": 1500000.50,
    "emission_date": "2025-10-20",
    "status": "pending"
  }
}
```

### Tipos de Eventos

- `customer.created` - Cliente creado
- `customer.fetched` - Cliente consultado
- `customer.listed` - Clientes listados
- `invoice.created` - Factura creada
- `invoice.fetched` - Factura consultada
- `invoice.listed` - Facturas listadas
- `invoice.error` - Error en operación de factura

## 🔐 Seguridad

- **JWT Authentication**: Todos los endpoints requieren autenticación
- **Secrets Management**: Variables de entorno para credenciales
- **CORS**: Configurado para APIs
- **Validaciones**: A nivel de dominio, aplicación y base de datos

## 📈 Escalabilidad

- **Microservicios independientes**: Cada servicio puede escalar individualmente
- **Bases de datos separadas**: No hay punto único de falla
- **Event-driven**: Comunicación asíncrona reduce acoplamiento
- **Stateless**: Servicios sin estado facilitan balanceo de carga

## 🐛 Troubleshooting

### PostgreSQL no se conecta
```bash
# Verificar que PostgreSQL esté listo
docker logs factumarket-postgres

# Verificar conexión
docker exec -it factumarket-postgres psql -U postgres -c "\l"
```

### RabbitMQ no recibe eventos
```bash
# Verificar management UI
open http://localhost:15672
# user: guest, password: guest

# Ver exchanges y queues
```

### MongoDB no conecta
```bash
docker exec -it factumarket-mongodb mongosh
# Verificar que la base esté creada
show dbs
```

## 📝 Notas Adicionales

- Los servicios están configurados para reiniciar automáticamente en caso de fallo
- Los datos persisten en volúmenes de Docker
- El Event Consumer corre en el mismo contenedor que Audit Service
- JWT secret key debe cambiarse en producción

## 📂 Estructura del Repositorio

```
factumarket-microservices/
├── .git/                           # Repositorio Git
├── .gitignore                      # Archivos ignorados por Git
├── README.md                       # Este archivo - Documentación principal
├── QUICK_START.md                  # Guía rápida de inicio (5 minutos)
├── MANUAL_TESTING_GUIDE.md         # Guía completa de pruebas manuales (68 casos)
├── TESTING_CHECKLIST.md            # Checklist interactivo de pruebas
├── run_tests.sh                    # Script automatizado de pruebas
├── docker-compose.yml              # Orquestación de todos los servicios
│
├── customer-service/               # Microservicio de Clientes
│   ├── app/
│   │   ├── controllers/            # Controladores MVC
│   │   │   └── clientes_controller.rb
│   │   ├── models/                 # Modelos MVC
│   │   │   └── customer.rb
│   │   └── concerns/               # JWT Authentication
│   ├── config/
│   │   ├── database.yml            # Configuración PostgreSQL
│   │   └── routes.rb               # Rutas API REST
│   ├── db/
│   │   ├── migrate/                # Migraciones de base de datos
│   │   └── seeds.rb                # Datos de prueba
│   ├── lib/
│   │   └── event_publisher.rb      # Publicador de eventos RabbitMQ
│   ├── Gemfile                     # Dependencias Ruby
│   └── Dockerfile                  # Imagen Docker
│
├── invoice-service/                # Microservicio de Facturas (Clean Architecture)
│   ├── app/
│   │   ├── domain/                 # 🏛️ Capa de Dominio (Clean Architecture)
│   │   │   ├── entities/
│   │   │   │   └── invoice.rb      # Entidad con lógica de negocio pura
│   │   │   └── repositories/
│   │   │       └── invoice_repository.rb  # Interfaz del repositorio
│   │   ├── application/            # 🎯 Capa de Aplicación (Clean Architecture)
│   │   │   ├── use_cases/
│   │   │   │   ├── create_invoice.rb     # Caso de uso: Crear factura
│   │   │   │   ├── get_invoice.rb        # Caso de uso: Obtener factura
│   │   │   │   └── list_invoices.rb      # Caso de uso: Listar facturas
│   │   │   └── services/
│   │   │       └── customer_validator.rb  # Interfaz validador
│   │   ├── infrastructure/         # 🔧 Capa de Infraestructura (Clean Architecture)
│   │   │   ├── persistence/
│   │   │   │   └── oracle_invoice_repository.rb  # Implementación repositorio
│   │   │   ├── http/
│   │   │   │   └── customer_http_validator.rb    # Cliente HTTP
│   │   │   └── messaging/
│   │   │       └── rabbitmq_event_publisher.rb   # Publisher RabbitMQ
│   │   ├── controllers/            # 🌐 Capa de Interface (MVC)
│   │   │   └── facturas_controller.rb
│   │   └── models/
│   │       └── invoice_model.rb    # ActiveRecord (solo persistencia)
│   ├── spec/                       # 🧪 Pruebas Unitarias RSpec
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── invoice_spec.rb # Tests de entidad de dominio
│   │   └── application/
│   │       └── use_cases/
│   │           └── create_invoice_spec.rb  # Tests de caso de uso
│   ├── config/
│   │   ├── database.yml            # Configuración PostgreSQL
│   │   └── routes.rb               # Rutas API REST
│   ├── db/migrate/                 # Migraciones de base de datos
│   ├── Gemfile                     # Dependencias Ruby
│   └── Dockerfile                  # Imagen Docker
│
├── audit-service/                  # Microservicio de Auditoría
│   ├── app/
│   │   ├── controllers/            # Controladores MVC
│   │   │   └── auditoria_controller.rb
│   │   └── models/                 # Modelos Mongoid (MongoDB)
│   │       └── audit_event.rb
│   ├── config/
│   │   ├── mongoid.yml             # Configuración MongoDB
│   │   ├── initializers/
│   │   │   └── mongoid.rb          # Inicialización Mongoid
│   │   └── routes.rb               # Rutas API REST
│   ├── lib/
│   │   └── event_consumer.rb       # Consumidor de eventos RabbitMQ
│   ├── Gemfile                     # Dependencias Ruby
│   └── Dockerfile                  # Imagen Docker
│
└── docs/                           # (Implícito en archivos .md)
    ├── Arquitectura y diseño       # README.md
    ├── Guía rápida                 # QUICK_START.md
    ├── Pruebas manuales            # MANUAL_TESTING_GUIDE.md
    └── Checklist de pruebas        # TESTING_CHECKLIST.md
```

### Archivos Clave

| Archivo | Descripción |
|---------|-------------|
| `docker-compose.yml` | Orquestación completa de los 6 servicios (PostgreSQL, MongoDB, RabbitMQ, Customer, Invoice, Audit) |
| `README.md` | Documentación técnica completa con arquitectura, APIs y configuración |
| `QUICK_START.md` | Guía para levantar el sistema en 5 minutos con ejemplos de uso |
| `MANUAL_TESTING_GUIDE.md` | 68 casos de prueba detallados paso a paso |
| `TESTING_CHECKLIST.md` | Checklist interactivo para verificar todos los componentes |
| `run_tests.sh` | Script bash para ejecutar todas las pruebas automáticamente |

### Principios Arquitectónicos Aplicados

- **Microservicios**: 3 servicios independientes con bases de datos separadas
- **Clean Architecture**: Implementada en Invoice Service con 4 capas bien definidas
- **MVC Pattern**: Controllers, Models, y Views (JSON) en todos los servicios
- **Event-Driven**: Comunicación asíncrona mediante RabbitMQ
- **Dependency Injection**: Inyección de dependencias en casos de uso
- **Repository Pattern**: Abstracción de persistencia en capa de dominio
- **SOLID Principles**: Separación de responsabilidades y inversión de dependencias

## 👥 Autor

**Daniel E. Londoño**
Backend Developer
📧 daniel.esloh@gmail.com

Prueba Técnica para Double V Partners NYX - Octubre 2025

## 📄 Licencia

Este proyecto es parte de una prueba técnica para Double V Partners NYX.
