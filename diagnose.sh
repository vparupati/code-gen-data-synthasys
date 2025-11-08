#!/bin/bash
# ============================================================================
# Docker Setup Diagnostic Script
# ============================================================================

echo "============================================================================"
echo "Docker Setup Diagnostics"
echo "============================================================================"
echo ""

# Check Docker
echo "1. Checking Docker..."
if command -v docker &> /dev/null; then
    echo "   ✓ Docker command found"
    if docker info > /dev/null 2>&1; then
        echo "   ✓ Docker daemon is running"
        DOCKER_RUNNING=true
    else
        echo "   ✗ Docker daemon is NOT running"
        echo "   → Please start Docker Desktop"
        DOCKER_RUNNING=false
    fi
else
    echo "   ✗ Docker not installed"
    DOCKER_RUNNING=false
fi
echo ""

if [ "$DOCKER_RUNNING" = true ]; then
    # Check containers
    echo "2. Checking containers..."
    if docker ps -a | grep -q payment_postgres; then
        echo "   ✓ payment_postgres container exists"
        docker ps -a | grep payment_postgres
    else
        echo "   ✗ payment_postgres container not found"
    fi
    
    if docker ps -a | grep -q payment_mongodb; then
        echo "   ✓ payment_mongodb container exists"
        docker ps -a | grep payment_mongodb
    else
        echo "   ✗ payment_mongodb container not found"
    fi
    echo ""
    
    # Check if containers are running
    echo "3. Container status..."
    docker-compose ps 2>/dev/null || echo "   ⚠ docker-compose ps failed"
    echo ""
    
    # Check logs
    echo "4. Recent PostgreSQL logs (last 20 lines)..."
    docker-compose logs --tail=20 postgres 2>/dev/null || echo "   ⚠ Could not get logs"
    echo ""
    
    echo "5. Recent MongoDB logs (last 20 lines)..."
    docker-compose logs --tail=20 mongodb 2>/dev/null || echo "   ⚠ Could not get logs"
    echo ""
    
    # Check ports
    echo "6. Checking ports..."
    if lsof -i :5433 > /dev/null 2>&1; then
        echo "   ⚠ Port 5433 is in use:"
        lsof -i :5433
    else
        echo "   ✓ Port 5433 is available"
    fi
    
    if lsof -i :27017 > /dev/null 2>&1; then
        echo "   ⚠ Port 27017 is in use:"
        lsof -i :27017
    else
        echo "   ✓ Port 27017 is available"
    fi
    echo ""
    
    # Check volumes
    echo "7. Checking volumes..."
    docker volume ls | grep payment || echo "   No payment volumes found"
    echo ""
    
    # Check files
    echo "8. Checking required files..."
    for file in docker-compose.yml init_postgresql.sql init_mongodb.js; do
        if [ -f "$file" ]; then
            echo "   ✓ $file exists"
        else
            echo "   ✗ $file is MISSING"
        fi
    done
    echo ""
fi

echo "============================================================================"
echo "Common Issues & Solutions:"
echo "============================================================================"
echo ""
echo "If Docker daemon is not running:"
echo "  1. Open Docker Desktop"
echo "  2. Wait for it to fully start (whale icon should be steady)"
echo "  3. Try: docker info"
echo ""
echo "If containers fail to start:"
echo "  1. Check logs: docker-compose logs postgres"
echo "  2. Remove old containers: docker-compose down -v"
echo "  3. Start fresh: docker-compose up -d"
echo ""
echo "If init script fails:"
echo "  1. Check SQL syntax: psql -f init_postgresql.sql (dry run)"
echo "  2. Remove volumes and restart: docker-compose down -v && docker-compose up -d"
echo ""
echo "============================================================================"

