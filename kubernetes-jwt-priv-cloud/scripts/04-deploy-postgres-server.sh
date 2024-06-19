#!/bin/bash
# This script will check connection to the postgres server that was deployed at script #2
# Deploy this at a VM that Conjur can communicate with
#============ Variables ===============
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# Postgres server port
REMOTE_DB_PORT=5433
#================ Script ==============
$SUDO $CONTAINER_MGR run --name zoo-demo-db -p ${REMOTE_DB_PORT}:5432 -d docker.io/assafhazan/postgres-zoo-demo:v11.2
