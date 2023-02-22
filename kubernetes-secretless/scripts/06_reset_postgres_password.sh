#!/bin/bash
# This script will rotate a postgres user password
# Make sure to edit .env before running this script
#============ Variables ===============
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# Postgres server host
REMOTE_DB_HOST=aws-pub-lab
# Postgres server port
REMOTE_DB_PORT=5432
#================ Script ==============
$SUDO $CONTAINER_MGR run --rm -i -e PGPASSWORD=123456 postgres:11.2-alpine \
    psql -U admin "postgres://${REMOTE_DB_HOST}:${REMOTE_DB_PORT}/postgres" \
    << EOSQL

ALTER USER reception WITH PASSWORD 'vet_123456';

EOSQL

conjur variable set -i "kubernetes/applications/safe/postgres-password" -v "vet_123456"