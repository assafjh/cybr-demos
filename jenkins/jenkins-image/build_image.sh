#!/bin/bash
#=======
CONTAINER_MGR=podman
#=======
"$CONTAINER_MGR" build --tag docker.io/assafhazan/jenkins:conjur -f ./Dockerfile
"$CONTAINER_MGR" login docker.io -u assafhazan
"$CONTAINER_MGR" push docker.io/assafhazan/jenkins:conjur
