# Payment Processing Database - CRUD Operations & Verification

This repository contains comprehensive CRUD operations for both PostgreSQL and MongoDB implementations of a payment processing data model, along with Docker-based verification setup.

## 📁 Repository Structure

```
.
├── payment_model_postgresql.md          # PostgreSQL database schema documentation
├── payment_model_mongodb.md            # MongoDB database schema documentation
├── postgresql_crud_operations.sql      # Comprehensive PostgreSQL CRUD examples
├── mongodb_crud_operations.js           # Comprehensive MongoDB CRUD examples
├── docker-compose.yml                   # Docker Compose configuration
├── init_postgresql.sql                  # PostgreSQL initialization script
├── init_mongodb.js                      # MongoDB initialization script
├── test_postgresql.sh                  # PostgreSQL test script
├── test_mongodb.js                     # MongoDB test script
└── README.md                           # This file
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- For PostgreSQL tests: `psql` client (or use Docker exec)
- For MongoDB tests: `mongosh` client (or use Docker exec)

### 1. Start the Databases

Start both PostgreSQL and MongoDB using Docker Compose:

```bash
docker-compose up -d
```

This will:
- Start PostgreSQL on port `5433` (to avoid conflicts with local PostgreSQL)
- Start MongoDB on port `27017`
- Automatically initialize both databases with schemas and sample data

### 2. Verify Services are Running

Check that both services are healthy:

```bash
docker-compose ps
```

You should see both `payment_postgres` and `payment_mongodb` with status "Up (healthy)".

### 3. Run Test Scripts

#### Test PostgreSQL CRUD Operations

```bash
./test_postgresql.sh
```

Or using Docker exec:

```bash
docker exec -i payment_postgres psql -U payment_user -d payment_db < test_postgresql.sh
```

#### Test MongoDB CRUD Operations

```bash
docker exec -i payment_mongodb mongosh -u payment_user -p payment_pass --authenticationDatabase admin payment_db < test_mongodb.js
```

Or using mongosh directly (if installed locally):

```bash
mongosh "mongodb://payment_user:payment_pass@localhost:27017/payment_db?authSource=admin" test_mongodb.js
```

## 📊 Database Connection Details

### PostgreSQL

- **Host:** `localhost`
- **Port:** `5433` (changed from 5432 to avoid conflicts)
- **Database:** `payment_db`
- **Username:** `payment_user`
- **Password:** `payment_pass`

**Connection String:**
```
postgresql://payment_user:payment_pass@localhost:5433/payment_db
```

**Using psql:**
```bash
psql -h localhost -p 5433 -U payment_user -d payment_db
```

### MongoDB

- **Host:** `localhost`
- **Port:** `27017`
- **Database:** `payment_db`
- **Username:** `payment_user`
- **Password:** `payment_pass`
- **Auth Database:** `admin`

**Connection String:**
```
mongodb://payment_user:payment_pass@localhost:27017/payment_db?authSource=admin
```

**Using mongosh:**
```bash
mongosh "mongodb://payment_user:payment_pass@localhost:27017/payment_db?authSource=admin"
```

## 📝 Using the CRUD Operation Files

### PostgreSQL Operations

The `postgresql_crud_operations.sql` file contains comprehensive CRUD examples for all tables:

- **Institutions** - Bank/financial institution data
- **Parties** - Debtors, creditors, intermediaries
- **Party Identifiers** - IBAN, account numbers, etc.
- **Messages** - Payment message batches
- **Message Events** - Message state transition history
- **Payments** - Individual payment records
- **Payment Events** - Payment state transition history
- **Payment Route Steps** - Intermediary routing information

**Run specific operations:**
```bash
# Run all operations
psql -h localhost -U payment_user -d payment_db -f postgresql_crud_operations.sql

# Run specific section (using grep and psql)
psql -h localhost -U payment_user -d payment_db -c "$(grep -A 20 'INSTITUTIONS - CREATE' postgresql_crud_operations.sql)"
```

### MongoDB Operations

The `mongodb_crud_operations.js` file contains comprehensive CRUD examples for all collections:

- **institutions** - Bank/financial institution documents
- **parties** - Debtors, creditors, intermediaries (with embedded identifiers)
- **messages** - Payment message batches (with embedded payment IDs)
- **payments** - Individual payment documents (with embedded state_history and route_steps)

**Run specific operations:**
```bash
# Run all operations
mongosh "mongodb://payment_user:payment_pass@localhost:27017/payment_db?authSource=admin" mongodb_crud_operations.js

# Run specific section (copy/paste into mongosh)
mongosh "mongodb://payment_user:payment_pass@localhost:27017/payment_db?authSource=admin"
# Then copy/paste the desired section from mongodb_crud_operations.js
```

## 🧪 Test Scripts

### PostgreSQL Test Script (`test_postgresql.sh`)

Tests 13 different CRUD operations:
1. CREATE - Insert institution
2. READ - Get institutions
3. CREATE - Insert party
4. READ - Get parties with join
5. CREATE - Insert message
6. READ - Query JSONB attributes
7. CREATE - Insert payment
8. READ - Get payments with message join
9. UPDATE - Update payment state
10. CREATE - Insert payment event
11. READ - Get payment event history
12. READ - Analytics query
13. DELETE - Cleanup test data

### MongoDB Test Script (`test_mongodb.js`)

Tests 13 different CRUD operations:
1. CREATE - Insert institution
2. READ - Get institutions
3. CREATE - Insert party
4. READ - Get parties with aggregation
5. CREATE - Insert message
6. READ - Query nested attributes
7. CREATE - Insert payment
8. READ - Get payments with lookup
9. UPDATE - Update payment state with state_history
10. READ - Get payment state history
11. UPDATE - Add route step
12. READ - Analytics query
13. DELETE - Cleanup test data

## 🔧 Database Management

### Stop the Databases

```bash
docker-compose down
```

### Stop and Remove Volumes (Clean Slate)

```bash
docker-compose down -v
```

This will remove all data. Next time you start, databases will be re-initialized.

### View Logs

```bash
# All services
docker-compose logs

# PostgreSQL only
docker-compose logs postgres

# MongoDB only
docker-compose logs mongodb
```

### Access Database Shells

**PostgreSQL:**
```bash
docker exec -it payment_postgres psql -U payment_user -d payment_db
```

**MongoDB:**
```bash
docker exec -it payment_mongodb mongosh -u payment_user -p payment_pass --authenticationDatabase admin payment_db
```

## 📚 CRUD Operations Coverage

### CREATE Operations
- Single insert
- Bulk insert
- Insert with relationships/foreign keys
- Insert with JSONB/embedded documents
- Idempotent inserts (ON CONFLICT / upsert)

### READ Operations
- Get by ID
- Get all with pagination
- Filter by various fields
- Join/aggregation queries
- Complex queries (state transitions, date ranges)
- JSONB/embedded document queries
- Analytics and reporting queries

### UPDATE Operations
- Update single field
- Update multiple fields
- Conditional updates
- State transitions with event logging
- Array operations (MongoDB: $push, $pull, $set)
- JSONB field updates

### DELETE Operations
- Delete by ID
- Conditional delete
- Cascade considerations
- Cleanup operations

### Special Operations
- State transitions with event logging
- Route step management
- Event history queries
- Transaction examples
- Idempotency patterns

## 🎯 Use Cases

These CRUD operations are designed for:

1. **SLM Training** - Training Small Language Models on:
   - Text-to-SQL conversion
   - Text-to-NoSQL conversion
   - SQL ↔ NoSQL bidirectional translation

2. **Database Learning** - Understanding differences between:
   - Relational (PostgreSQL) vs Document (MongoDB) models
   - SQL vs NoSQL query patterns
   - Normalized vs Denormalized data structures

3. **API Development** - Reference implementations for:
   - REST API endpoints
   - Database abstraction layers
   - Data access patterns

## 🔍 Verification Checklist

After running the test scripts, verify:

- [ ] All CREATE operations succeed
- [ ] All READ operations return expected data
- [ ] All UPDATE operations modify data correctly
- [ ] All DELETE operations remove data
- [ ] Foreign key relationships work (PostgreSQL)
- [ ] Embedded documents work (MongoDB)
- [ ] JSONB queries work (PostgreSQL)
- [ ] Aggregation pipelines work (MongoDB)
- [ ] State transitions log events correctly
- [ ] Indexes are created and used

## 🐛 Troubleshooting

### PostgreSQL Connection Issues

```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Check PostgreSQL logs
docker logs payment_postgres

# Test connection
docker exec -it payment_postgres psql -U payment_user -d payment_db -c "SELECT version();"
```

### MongoDB Connection Issues

```bash
# Check if MongoDB is running
docker ps | grep mongodb

# Check MongoDB logs
docker logs payment_mongodb

# Test connection
docker exec -it payment_mongodb mongosh -u payment_user -p payment_pass --authenticationDatabase admin --eval "db.adminCommand('ping')"
```

### Permission Issues

If test scripts fail with permission errors:

```bash
chmod +x test_postgresql.sh
```

### Port Conflicts

If ports 5432 or 27017 are already in use, modify `docker-compose.yml` to use different ports:

```yaml
ports:
  - "5433:5432"  # Change PostgreSQL port
  - "27018:27017"  # Change MongoDB port
```

## 📖 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 📄 License

This project is provided as-is for educational and training purposes.

