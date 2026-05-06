#!/bin/bash
# This Script deploys the companydb demo PostgreSQL server

set -euo pipefail

#============ Variables ===============
CONTAINER_MGR="docker"
SUDO="" # Set to 'sudo' if required
REMOTE_DB_PORT=5433
CONTAINER_NAME="companydb-demo"
IMAGE_NAME="ghcr.io/assafjh/postgres-companydb:latest"

# DB Credentials (aligned with companydb schema — reporting_service_ro is read-only)
DB_USER="reporting_service_ro"
DB_PASS="reporting123"
DB_NAME="postgres"

#================ Script ==============

echo "🧹 Cleaning up old containers if they exist..."
$SUDO $CONTAINER_MGR rm -f $CONTAINER_NAME > /dev/null 2>&1 || true

echo "🚀 Starting PostgreSQL container ($CONTAINER_NAME)..."
$SUDO $CONTAINER_MGR run --name $CONTAINER_NAME \
    -p ${REMOTE_DB_PORT}:5432 \
    -d $IMAGE_NAME

# Improved Health Check
echo "⏳ Waiting for PostgreSQL to be ready..."
MAX_RETRIES=10
COUNT=0
until $SUDO $CONTAINER_MGR exec $CONTAINER_NAME pg_isready -U $DB_USER -d $DB_NAME > /dev/null 2>&1 || [ $COUNT -eq $MAX_RETRIES ]; do
    echo "   ...still waiting ($((COUNT+1))/$MAX_RETRIES)"
    sleep 2
    COUNT=$((COUNT+1))
done

if [ $COUNT -eq $MAX_RETRIES ]; then
    echo "❌ Error: PostgreSQL failed to start in time."
    exit 1
fi

# Final Table Verification
echo "🔍 Verifying 'customers' table structure..."
$SUDO $CONTAINER_MGR run --rm --network host \
    -e PGPASSWORD=$DB_PASS \
    postgres:17-alpine \
    psql -h localhost -p $REMOTE_DB_PORT -U $DB_USER -d $DB_NAME -c "\d customers"

echo "✅ PostgreSQL server is running and the customers table is ready."
echo "   Access it at: localhost:$REMOTE_DB_PORT"