#!/bin/bash
# This script will check connection to the postgres server that was deployed at script #2
#============ Variables ===============
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# Postgres server host
REMOTE_DB_HOST=aws-pub-lab
# Postgres server port
REMOTE_DB_PORT=5452
#================ Script ==============
$SUDO $CONTAINER_MGR run --rm -it -e PGPASSWORD=vet_123456 postgres:15.2-alpine \
  psql -U reception "postgres://${REMOTE_DB_HOST}:${REMOTE_DB_PORT}/vet" -c "\d zoo"

