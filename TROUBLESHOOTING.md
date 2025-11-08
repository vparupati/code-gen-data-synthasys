# Troubleshooting Guide

## Issue: Docker daemon not running

**Error:** `Cannot connect to the Docker daemon at unix:///Users/vparupati/.docker/run/docker.sock`

**Solution:**
1. Open Docker Desktop application
2. Wait for Docker to fully start (whale icon in menu bar should be steady)
3. Try again: `docker-compose up -d`

## Issue: Port already in use

**Error:** `Bind for 0.0.0.0:5432 failed: port is already allocated`

**Solution:**
The docker-compose.yml has been updated to use port 5433 for PostgreSQL to avoid conflicts.

If you need to use different ports, edit `docker-compose.yml`:
```yaml
ports:
  - "5433:5432"  # Change first number to any available port
```

## Issue: MongoDB authentication errors

**Error:** `Authentication failed` or `not authorized`

**Solution:**
MongoDB uses the root user created by `MONGO_INITDB_ROOT_USERNAME` for the healthcheck.
The init script also creates a `payment_user` for the `payment_db` database.

**Connection options:**

1. **Using root user (admin database):**
```bash
mongosh -u payment_user -p payment_pass --authenticationDatabase admin payment_db
```

2. **Using payment_db user (after init):**
```bash
mongosh -u payment_user -p payment_pass --authenticationDatabase payment_db payment_db
```

## Issue: Containers start but immediately stop

**Check logs:**
```bash
docker-compose logs postgres
docker-compose logs mongodb
```

**Common causes:**
- Init script syntax errors
- Permission issues with volume mounts
- Database already initialized (delete volumes)

**Fix:**
```bash
# Stop and remove everything
docker-compose down -v

# Start fresh
docker-compose up -d

# Check logs
docker-compose logs -f
```

## Issue: Init scripts not running

**Symptoms:** Databases start but no tables/collections exist

**Check:**
```bash
# PostgreSQL
docker exec -it payment_postgres psql -U payment_user -d payment_db -c "\dt"

# MongoDB
docker exec -it payment_mongodb mongosh -u payment_user -p payment_pass --authenticationDatabase admin payment_db --eval "show collections"
```

**Fix:**
Init scripts only run on first initialization. To re-run:
```bash
docker-compose down -v  # Removes volumes
docker-compose up -d     # Re-initializes
```

## Issue: Healthcheck failures

**Check health status:**
```bash
docker-compose ps
```

**If unhealthy:**
```bash
# Check specific service logs
docker-compose logs postgres
docker-compose logs mongodb

# Restart service
docker-compose restart postgres
docker-compose restart mongodb
```

## Issue: Permission denied on test scripts

**Error:** `Permission denied: ./test_postgresql.sh`

**Solution:**
```bash
chmod +x test_postgresql.sh
```

## Issue: Connection refused

**Check if containers are running:**
```bash
docker ps
```

**If not running:**
```bash
docker-compose up -d
docker-compose ps
```

**If running but can't connect:**
- Verify ports are correct in docker-compose.yml
- Check firewall settings
- Try connecting from within container:
  ```bash
  docker exec -it payment_postgres psql -U payment_user -d payment_db
  ```

## Quick Diagnostic Commands

```bash
# Check Docker status
docker info

# Check container status
docker-compose ps

# View all logs
docker-compose logs

# View recent logs
docker-compose logs --tail=50

# Restart all services
docker-compose restart

# Stop all services
docker-compose down

# Stop and remove volumes (fresh start)
docker-compose down -v
docker-compose up -d
```

## Getting Help

If issues persist:
1. Check Docker Desktop is running and up to date
2. Review logs: `docker-compose logs`
3. Verify file permissions and paths
4. Ensure ports 5433 and 27017 are available

