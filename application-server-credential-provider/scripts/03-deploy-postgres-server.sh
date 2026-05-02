#!/bin/bash
# This Script deploys a demo PostgreSQL server for the Zoo Application

set -euo pipefail

#============ Variables ===============
CONTAINER_MGR="docker"
SUDO="" # Set to 'sudo' if required
REMOTE_DB_PORT=5433
CONTAINER_NAME="zoo-demo-db"
IMAGE_NAME="docker.io/assafhazan/postgres-zoo-demo:v11.2"

# DB Credentials (Aligned with ZooServlet demo)
DB_USER="reception"
DB_PASS="vet_123456"
DB_NAME="vet"

#================ Script ==============

echo "🧹 Cleaning up old containers if they exist..."
$SUDO $CONTAINER_MGR rm -f $CONTAINER_NAME > /dev/null 2>&1 || true

echo "🚀 Starting PostgreSQL container ($CONTAINER_NAME)..."
$SUDO $CONTAINER_MGR run --name $CONTAINER_NAME \
    -p ${REMOTE_DB_PORT}:5432 \
    -e POSTGRES_PASSWORD=$DB_PASS \
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
echo "🔍 Verifying 'zoo' table structure..."
$SUDO $CONTAINER_MGR run --rm --network host \
    -e PGPASSWORD=$DB_PASS \
    postgres:11.2-alpine \
    psql -h localhost -p $REMOTE_DB_PORT -U $DB_USER -d $DB_NAME -c "\d zoo"

echo "✅ PostgreSQL server is running and the Zoo table is ready."
echo "   Access it at: localhost:$REMOTE_DB_PORT"