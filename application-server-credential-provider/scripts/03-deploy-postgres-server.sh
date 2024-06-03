#!/bin/bash
# This Script deploys a demo postgres server
#============ Variables ===============
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# Postgres server port
REMOTE_DB_PORT=5433
#================ Script ==============
echo "Starting PostgreSQL container..."
$SUDO $CONTAINER_MGR run --name zoo-demo-db -p ${REMOTE_DB_PORT}:5432 -d docker.io/assafhazan/postgres-zoo-demo:v11.2

if [ $? -ne 0 ]; then
  echo "Failed to start PostgreSQL container"
  exit 1
fi

# Wait a few seconds for the server to start
sleep 2

# Check connectivity
echo "Checking PostgreSQL connectivity..."
$SUDO $CONTAINER_MGR run --rm -it -e PGPASSWORD=vet_123456 postgres:11.2-alpine \
  psql -U reception "postgres://$(hostname):${REMOTE_DB_PORT}/vet" -c "\d zoo"

if [ $? -ne 0 ]; then
  echo "Failed to connect to PostgreSQL"
  exit 1
fi

echo "PostgreSQL server is running and accessible."
