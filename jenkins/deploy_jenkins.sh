#!/bin/bash
#====
SUDO=
CONTAINER_MGR=podman
CONTAINER_IMG=docker.io/assafhazan/jenkins:conjur
JENKINS_ADDRESS=
JENKINS_PORT=8080
#====
$CONTAINER_MGR container run \
  --name jenkins \
  --detach \
  --privileged \
  --publish $PORT:8080 \
  --env JENKINS_ADMIN_ID= \
  --env JENKINS_ADMIN_PASSWORD= \
  --env JENKINS_ADDRESS="$JENKINS_ADDRESS" \
  --env JENKINS_PORT="$JENKINS_PORT" \
  $CONTAINER_IMG