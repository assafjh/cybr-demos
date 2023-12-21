#!/bin/bash
# This script will deploy a TeamCity server instance

#================ Internal =======================
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) 
TEAMCITY_DATA_FOLDER="$SCRIPT_DIR"/teamcity/server

#================ Variables =======================
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# TeamCity server port
TEAMCITY_SERVER_PORT=8111

#================ Script =======================
# Create folders for volume mounts 
mkdir -p "$TEAMCITY_DATA_FOLDER"/{datadir,logs}

# Deploying server
$SUDO $CONTAINER_MGR run --name teamcity-server \
    --detach \
    --restart=unless-stopped \
    -v "$TEAMCITY_DATA_FOLDER"/datadir:/data/teamcity_server/datadir \
    -v "$TEAMCITY_DATA_FOLDER"/logs:/opt/teamcity/logs  \
    -p $TEAMCITY_SERVER_PORT:8111 \
    jetbrains/teamcity-server:latest
