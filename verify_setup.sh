#!/bin/bash
# ============================================================================
# Setup Verification Script
# ============================================================================
# This script verifies that all required files are in place
# ============================================================================

set -e

echo "============================================================================"
echo "Verifying Setup Files"
echo "============================================================================"
echo ""

# Check required files
REQUIRED_FILES=(
  "docker-compose.yml"
  "init_postgresql.sql"
  "init_mongodb.js"
  "test_postgresql.sh"
  "test_mongodb.js"
  "postgresql_crud_operations.sql"
  "mongodb_crud_operations.js"
  "README.md"
)

MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "✓ $file exists"
  else
    echo "✗ $file is MISSING"
    MISSING_FILES+=("$file")
  fi
done

echo ""

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
  echo "✓ All required files are present"
else
  echo "✗ Missing files: ${MISSING_FILES[*]}"
  exit 1
fi

echo ""

# Check file permissions
echo "Checking file permissions..."
if [ -x "test_postgresql.sh" ]; then
  echo "✓ test_postgresql.sh is executable"
else
  echo "✗ test_postgresql.sh is not executable (fixing...)"
  chmod +x test_postgresql.sh
  echo "✓ Fixed"
fi

echo ""

# Check Docker Compose syntax
echo "Validating docker-compose.yml..."
if command -v docker-compose &> /dev/null || command -v docker &> /dev/null; then
  if docker compose config > /dev/null 2>&1 || docker-compose config > /dev/null 2>&1; then
    echo "✓ docker-compose.yml is valid"
  else
    echo "⚠ docker-compose.yml validation failed (Docker may not be running)"
  fi
else
  echo "⚠ Docker not found - skipping docker-compose validation"
fi

echo ""

# Check SQL syntax (basic)
echo "Checking SQL files..."
if command -v psql &> /dev/null; then
  echo "✓ psql found - can test PostgreSQL scripts"
else
  echo "⚠ psql not found - will need Docker to test PostgreSQL"
fi

# Check MongoDB shell
if command -v mongosh &> /dev/null; then
  echo "✓ mongosh found - can test MongoDB scripts"
else
  echo "⚠ mongosh not found - will need Docker to test MongoDB"
fi

echo ""
echo "============================================================================"
echo "Setup Verification Complete"
echo "============================================================================"
echo ""
echo "Next steps:"
echo "1. Start databases: docker-compose up -d"
echo "2. Wait for services: docker-compose ps"
echo "3. Run PostgreSQL tests: ./test_postgresql.sh"
echo "4. Run MongoDB tests: docker exec -i payment_mongodb mongosh -u payment_user -p payment_pass --authenticationDatabase admin payment_db < test_mongodb.js"
echo ""

