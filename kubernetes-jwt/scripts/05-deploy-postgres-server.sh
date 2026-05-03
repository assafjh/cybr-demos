#!/bin/bash

set -euo pipefail

# Deploys a demo PostgreSQL server for use with the Secretless Broker and Spring Boot use cases.
# Run this on a VM that is reachable from the Kubernetes cluster.
#============ Variables ===============
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# Postgres server port
REMOTE_DB_PORT=5432
#================ Script ==============
$SUDO $CONTAINER_MGR run --name zoo-demo-db -p ${REMOTE_DB_PORT}:5432 -d docker.io/assafhazan/postgres-zoo-demo:v11.2
