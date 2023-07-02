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
$SUDO $CONTAINER_MGR volume create gitlab-runner-conjur-config
    # If there is a need to add custom hosts, add to the command the add-host flag - example below
    #--add-host custom-host:127.0.0.1 \
$SUDO $CONTAINER_MGR run -d --name gitlab-runner-conjur --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v gitlab-runner-conjur-config:/etc/gitlab-runner \
    "$CONTAINER_IMG"
# Registering GitLab runners
# CyberArk Docker Executors
    # If there is a need to add custom hosts, add to the command the add-host flag - example below
    #--add-host custom-host:127.0.0.1 \
    # If there is a need to add custom hosts, add to the register command the docker-extra-hosts flag - example below
    #--docker-extra-hosts custom-host:127.0.0.1 \
$SUDO $CONTAINER_MGR run --rm -it -v gitlab-runner-conjur-config:/etc/gitlab-runner \
    "$CONTAINER_IMG" register -u "http://$GITLAB_HOST:$GITLAB_PORT" -r "$GITLAB_REGISTRATION_TOKEN" \
    --description "Demo CyberArk Docker Executor" -n --tag-list "conjur-demo-docker" \
    --executor docker \
    --docker-image cyberark/authn-jwt-gitlab:ubuntu-1.0.0
# Shell Executor
$SUDO $CONTAINER_MGR run --rm -it -v gitlab-runner-conjur-config:/etc/gitlab-runner \
    "$CONTAINER_IMG" register -u "http://$GITLAB_HOST:$GITLAB_PORT" -r "$GITLAB_REGISTRATION_TOKEN" \
    --description "Demo Shell Executor" -n --tag-list "conjur-demo-shell" --executor shell
# Deploying Summon on the runner
$SUDO $CONTAINER_MGR exec -it gitlab-runner-conjur bash -c 'curl -sSL https://raw.githubusercontent.com/cyberark/summon/main/install.sh | bash'
$SUDO $CONTAINER_MGR exec -it gitlab-runner-conjur bash -c 'curl -sSL https://raw.githubusercontent.com/cyberark/summon-conjur/main/install.sh | bash'