#!/bin/bash
#============ Variables ===============
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# Docker image URL
CONTAINER_IMG=gitlab/gitlab-runner:latest
# GitLab Host
GITLAB_HOST=$(hostname -f)
# GitLab port
GITLAB_PORT=9080
# GitLab Instance Registration Token
GITLAB_REGISTRATION_TOKEN=
#============ Script ===============
#Deploying GitLab Runner
$SUDO $CONTAINER_MGR volume create gitlab-runner-config
$SUDO $CONTAINER_MGR run -d --name gitlab-runner --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v gitlab-runner-config:/etc/gitlab-runner \
    "$CONTAINER_IMG"
# Registering GitLab runner
$SUDO $CONTAINER_MGR run --rm -it -v gitlab-runner-config:/etc/gitlab-runner \
    "$CONTAINER_IMG" register -u "http://$GITLAB_HOST:$GITLAB_PORT" -r "$GITLAB_REGISTRATION_TOKEN" \
    --description "Demo Runner" -n --executor shell