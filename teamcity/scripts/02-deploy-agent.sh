#!/bin/bash
# This script will deploy a TeamCity agent instance
# After deploy, go and authorize the agent at TeamCity UI

#================ Internal =======================
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) 
TEAMCITY_DATA_FOLDER="$SCRIPT_DIR"/teamcity/agent

#================ Variables =======================
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker

#================ Script =======================
# Create folders for volume mounts 
mkdir -p "$TEAMCITY_DATA_FOLDER"/datadir

# Deploying agent
$SUDO $CONTAINER_MGR run --name teamcity-agent \
    --link teamcity-server \
    --env SERVER_URL=http://teamcity-server:8111 \
    --detach \
    --restart=unless-stopped \
    -v $TEAMCITY_DATA_FOLDER/datadir:/data/teamcity_agent/conf \
    jetbrains/teamcity-agent:latest

echo -e "Go to TeamCity UI -> Agents and authorize the new agent"