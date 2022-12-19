#!/bin/bash
#============ Variables ===============
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# Docker image URL
CONTAINER_IMG=gitlab/gitlab-ee:latest
# GitLab URL (usually, hostname)
GITLAB_ADDRESS=$(hostname -f)
# GitLab HTTP port
GITLAB_HTTP_PORT=9080
# GitLab SSH port
GITLAB_SSH_PORT=9022
# GitLab admin user password
GITLAB_ROOT_PASSWORD=
#============ Script ===============
#Deploying GitLab
$SUDO $CONTAINER_MGR run --detach \
  --hostname "$GITLAB_ADDRESS" \
  --publish "$GITLAB_HTTP_PORT":80 \
  --publish "$GITLAB_SSH_PORT":22 \
  --name gitlab-server \
  --restart always \
  --shm-size 256m \
  --env GITLAB_ROOT_PASSWORD="$GITLAB_ROOT_PASSWORD" \
  "$CONTAINER_IMG"

#Deploying GitLab Runner
$SUDO $CONTAINER_MGR volume create gitlab-runner-config
$SUDO $CONTAINER_MGR run -d --name gitlab-runner --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v gitlab-runner-config:/etc/gitlab-runner \
    gitlab/gitlab-runner:latest
