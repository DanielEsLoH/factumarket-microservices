# ✅ Testing Checklist - FactuMarket Microservices

Use this checklist to verify that all components are working correctly.

## 🚀 Quick Start Testing (Choose One)

### Option A: Automated Testing (Recommended - 2 minutes)

```bash
cd factumarket-microservices
./run_tests.sh
```

This script will automatically:
- ✅ Check all services are running
- ✅ Generate JWT token
- ✅ Test all endpoints
- ✅ Verify business rules
- ✅ Check databases
- ✅ Run unit tests
- ✅ Provide complete summary

### Option B: Manual Step-by-Step Testing (15 minutes)

Follow the comprehensive guide in `MANUAL_TESTING_GUIDE.md`

---

## 📋 Pre-Flight Checklist

Before testing, ensure:

```bash
# 1. Navigate to project directory
cd factumarket-microservices

# 2. Start all services
docker-compose up -d --build

# 3. Wait for services to be ready (2-3 minutes for first run)
# Watch logs to see when ready:
docker-compose logs -f | grep "Booting Puma"

# 4. Verify all containers are running
docker ps
# Expected: 6 containers running
```

**Checklist**:
- [ ] All 6 containers running (postgres, mongodb, rabbitmq, 3 services)
- [ ] No error messages in logs
- [ ] Health checks passing

---

## 🎯 Manual Testing Checklist

### Phase 1: Service Health ✅

```bash
# Test all health endpoints
curl http://localhost:3001/up  # Customer Service
curl http://localhost:3002/up  # Invoice Service
curl http://localhost:3003/up  # Audit Service
```

**Expected**: All return `200 OK`

- [ ] Customer Service health check passes
- [ ] Invoice Service health check passes
- [ ] Audit Service health check passes

### Phase 2: Database Setup ✅

```bash
# Create databases and run migrations
docker exec factumarket-customer-service rails db:create db:migrate
docker exec factumarket-invoice-service rails db:create db:migrate

# Load seed data
docker exec factumarket-customer-service rails db:seed
```

**Expected**: 5 customers created

- [ ] Customer database created
- [ ] Invoice database created
- [ ] Migrations executed successfully
- [ ] Seed data loaded (5 customers)

### Phase 3: Authentication ✅

```bash
# Generate JWT token
TOKEN=$(docker exec factumarket-customer-service rails runner "require 'jwt'; puts JWT.encode({user_id: 1, email: 'admin@factumarket.com', exp: (Time.now + 86400).to_i}, 'factumarket_secret_key_2025', 'HS256')")

echo $TOKEN
export TOKEN
```

**Expected**: Token string displayed

- [ ] JWT token generated successfully
- [ ] Token exported to environment variable

### Phase 4: Customer Service (MVC) ✅

```bash
# Test 1: List customers
curl -X GET http://localhost:3001/clientes \
  -H "Authorization: Bearer $TOKEN" | jq

# Test 2: Create customer
curl -X POST http://localhost:3001/clientes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "name": "Test Company",
      "identification": "TEST-001",
      "email": "test@company.com",
      "address": "Test Address"
    }
  }' | jq

# Test 3: Get specific customer
curl -X GET http://localhost:3001/clientes/1 \
  -H "Authorization: Bearer $TOKEN" | jq
```

**Checklist**:
- [ ] List customers returns 5+ customers
- [ ] Create customer succeeds (returns ID)
- [ ] Get customer by ID returns correct data
- [ ] Request without token returns 401 Unauthorized

### Phase 5: Invoice Service (Clean Architecture) ✅

```bash
# Test 1: Create valid invoice
curl -X POST http://localhost:3002/facturas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invoice": {
      "customer_id": 1,
      "amount": 1000000,
      "emission_date": "2025-10-20"
    }
  }' | jq

# Test 2: Validation - Negative amount (should fail)
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

# Test 3: Validation - Future date (should fail)
curl -X POST http://localhost:3002/facturas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invoice": {
      "customer_id": 1,
      "amount": 1000,
      "emission_date": "2026-12-31"
    }
  }' | jq

# Test 4: Inter-service validation - Invalid customer (should fail)
curl -X POST http://localhost:3002/facturas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invoice": {
      "customer_id": 9999,
      "amount": 1000,
      "emission_date": "2025-10-20"
    }
  }' | jq

# Test 5: Get invoice
curl -X GET http://localhost:3002/facturas/1 \
  -H "Authorization: Bearer $TOKEN" | jq

# Test 6: List invoices by date range
curl -X GET "http://localhost:3002/facturas?fechaInicio=2025-10-01&fechaFin=2025-10-31" \
  -H "Authorization: Bearer $TOKEN" | jq
```

**Checklist**:
- [ ] Valid invoice created successfully
- [ ] Tax calculated correctly (19% of amount)
- [ ] Total = amount + tax
- [ ] Negative amount rejected with error message
- [ ] Future date rejected with error message
- [ ] Invalid customer rejected (proves inter-service communication)
- [ ] Get invoice returns correct data
- [ ] List invoices by date range works

### Phase 6: Audit Service (Event-Driven) ✅

```bash
# Wait for events to be processed
sleep 5

# Test 1: List all audit events
curl -X GET http://localhost:3003/auditoria \
  -H "Authorization: Bearer $TOKEN" | jq

# Test 2: Filter by entity type
curl -X GET "http://localhost:3003/auditoria?entity_type=Invoice" \
  -H "Authorization: Bearer $TOKEN" | jq

# Test 3: Filter by service
curl -X GET "http://localhost:3003/auditoria?service=invoice_service" \
  -H "Authorization: Bearer $TOKEN" | jq

# Test 4: Get audit trail for specific invoice
curl -X GET http://localhost:3003/auditoria/1 \
  -H "Authorization: Bearer $TOKEN" | jq
```

**Checklist**:
- [ ] Audit events exist (count > 0)
- [ ] Events include: customer.created, invoice.created, etc.
- [ ] Filter by entity_type works
- [ ] Filter by service works
- [ ] Invoice-specific audit trail retrieved

### Phase 7: Database Verification ✅

```bash
# PostgreSQL - Check customers
docker exec factumarket-postgres psql -U postgres -d factumarket_customers_development -c "SELECT COUNT(*) FROM customers;"

# PostgreSQL - Check invoices
docker exec factumarket-postgres psql -U postgres -d factumarket_invoices_development -c "SELECT COUNT(*) FROM invoices;"

# MongoDB - Check audit events
docker exec factumarket-mongodb mongosh factumarket_audit_development --quiet --eval "db.audit_events.countDocuments()"
```

**Checklist**:
- [ ] PostgreSQL has customers (count > 5)
- [ ] PostgreSQL has invoices (count > 0)
- [ ] MongoDB has audit events (count > 0)

### Phase 8: RabbitMQ Verification ✅

Open in browser: http://localhost:15672

Login: `guest` / `guest`

**Checklist**:
- [ ] Exchange `factumarket_events` exists
- [ ] Queue `audit_service_queue` exists
- [ ] Queue has bindings to `customer.*` and `invoice.*`
- [ ] Messages are being processed (check Total/Rate)

### Phase 9: Unit Tests ✅

```bash
docker exec factumarket-invoice-service bundle exec rspec
```

**Expected**: All tests pass (0 failures)

**Checklist**:
- [ ] Domain entity tests pass (Invoice validations)
- [ ] Use case tests pass (CreateInvoice flow)
- [ ] All 20+ examples pass

---

## 🎯 Architecture Verification Checklist

### Clean Architecture (Invoice Service) ✅

Verify folder structure:
```bash
ls -R invoice-service/app/
```

**Expected structure**:
```
app/
├── domain/
│   ├── entities/
│   └── repositories/
├── application/
│   ├── use_cases/
│   └── services/
├── infrastructure/
│   ├── persistence/
│   ├── http/
│   └── messaging/
└── controllers/
```

**Checklist**:
- [ ] Domain layer exists (entities, repositories)
- [ ] Application layer exists (use cases, services)
- [ ] Infrastructure layer exists (implementations)
- [ ] Controllers exist (interface adapters)
- [ ] Dependencies flow inward (Clean Architecture principle)

### MVC Pattern ✅

**Checklist**:
- [ ] Controllers handle HTTP requests
- [ ] Models represent data (Customer, InvoiceModel, AuditEvent)
- [ ] Routes map URLs to controllers
- [ ] JSON responses as "Views"

### Microservices ✅

**Checklist**:
- [ ] 3 independent services running
- [ ] Each service has its own database
- [ ] Services communicate via HTTP (sync) and RabbitMQ (async)
- [ ] Services can be scaled independently

### Databases ✅

**Checklist**:
- [ ] PostgreSQL used for transactional data (customers, invoices)
- [ ] MongoDB used for audit logs (NoSQL)
- [ ] No shared database between services
- [ ] Each service owns its data

### Event-Driven Architecture ✅

**Checklist**:
- [ ] Events published to RabbitMQ
- [ ] Events consumed by Audit Service
- [ ] Loose coupling between services
- [ ] Asynchronous processing

---

## 📊 Success Criteria Summary

### Must Have (Critical) ✅

- [x] All 3 microservices running
- [x] Clean Architecture in Invoice Service
- [x] MVC pattern in all services
- [x] PostgreSQL database for customers and invoices
- [x] MongoDB for audit events
- [x] RabbitMQ for event messaging
- [x] JWT authentication on all endpoints
- [x] Business validations working (amount > 0, date not future)
- [x] Inter-service communication (Invoice → Customer)
- [x] Complete audit trail
- [x] Unit tests passing
- [x] Docker containerization

### Nice to Have (Bonus) ✅

- [x] Comprehensive documentation (README, guides)
- [x] Seed data for testing
- [x] Automated test script
- [x] Health check endpoints
- [x] Error handling
- [x] Logging

---

## 🐛 Troubleshooting

### Problem: Services not starting

**Solution**:
```bash
docker-compose down
docker-compose up -d --build
docker-compose logs -f
```

### Problem: PostgreSQL not ready

**Solution**: Wait a few seconds and check status:
```bash
docker exec factumarket-postgres pg_isready -U postgres
docker-compose logs postgres
```

### Problem: Migrations failing

**Solution**: Run manually:
```bash
docker exec factumarket-customer-service rails db:create db:migrate
docker exec factumarket-invoice-service rails db:create db:migrate
```

### Problem: Events not reaching Audit Service

**Solution**: Check RabbitMQ and Event Consumer:
```bash
docker-compose logs rabbitmq
docker-compose logs audit-service | grep "Event Consumer"
```

### Problem: JWT token expired

**Solution**: Generate new token:
```bash
TOKEN=$(docker exec factumarket-customer-service rails runner "require 'jwt'; puts JWT.encode({user_id: 1, email: 'admin@factumarket.com', exp: (Time.now + 86400).to_i}, 'factumarket_secret_key_2025', 'HS256')")
export TOKEN
```

---

## 🎉 Final Verification

Run the automated test script to verify everything:

```bash
./run_tests.sh
```

**Expected output**: All tests passing with summary showing:
- ✅ 10/10 Key achievements demonstrated
- ✅ All services healthy
- ✅ All tests passing

---

## 📚 Next Steps

After completing all tests:

1. **Review Architecture**: Read `README.md` for detailed architecture explanation
2. **Understand Clean Architecture**: Study `invoice-service/app/` structure
3. **Review Code**: Check domain entities, use cases, and infrastructure
4. **Run Unit Tests**: See `invoice-service/spec/` for test examples
5. **Explore APIs**: Use the curl examples to understand the system

---

✨ **You're ready to demonstrate the complete FactuMarket Microservices System!**
