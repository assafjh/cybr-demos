#!/bin/bash
#============ Variables ===============
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# Docker image URL
CONTAINER_IMG=gitlab/gitlab-ce:latest
# GitLab URL (if available, use the external hostname)
GITLAB_ADDRESS=
# GitLab HTTP port
GITLAB_HTTP_PORT=9080
# GitLab admin user password
GITLAB_ROOT_PASSWORD=
#============ Script ===============
#Deploying GitLab
$SUDO $CONTAINER_MGR run --detach \
  --hostname "$GITLAB_ADDRESS" \
  --publish "$GITLAB_HTTP_PORT":$GITLAB_HTTP_PORT \
  --name gitlab-server \
  --restart always \
  --shm-size 256m \
  --env GITLAB_ROOT_PASSWORD="$GITLAB_ROOT_PASSWORD" \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://$GITLAB_ADDRESS:$GITLAB_HTTP_PORT/';" \
  "$CONTAINER_IMG"