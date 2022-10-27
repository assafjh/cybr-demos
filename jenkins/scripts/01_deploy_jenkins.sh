#!/bin/bash
#============ Variables ===============
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=podman
# Docker image URL
CONTAINER_IMG=docker.io/assafhazan/jenkins:conjur
# Jenkins URL (usually, hostname)
JENKINS_ADDRESS=
# Jenkins port
JENKINS_PORT=8080
# Jenkins admin user ID
JENKINS_ADMIN_ID=
# Jenkins admin user password
JENKINS_ADMIN_PASSWORD=
# Conjur FQDN with scheme and port
CONJUR_FQDN=
CONJUR_ACCOUNT=demo
#============ Script ===============
$SUDO $CONTAINER_MGR container run \
  --name jenkins \
  --detach \
  --privileged \
  --publish "$JENKINS_PORT":8080 \
  --env JENKINS_ADMIN_ID="$JENKINS_ADMIN_ID" \
  --env JENKINS_ADMIN_PASSWORD="$JENKINS_ADMIN_PASSWORD" \
  --env JENKINS_ADDRESS="$JENKINS_ADDRESS" \
  --env JENKINS_PORT="$JENKINS_PORT" \
  --env CONJUR_FQDN="$CONJUR_FQDN" \
  --env CONJUR_ACCOUNT="$CONJUR_ACCOUNT"
  "$CONTAINER_IMG"
