#!/bin/bash
#=======
CONTAINER_MGR=docker
#=======
"$CONTAINER_MGR" build --no-cache --tag docker.io/assafhazan/push-to-k8s-secrets:latest .
"$CONTAINER_MGR" login docker.io -u assafhazan
"$CONTAINER_MGR" push docker.io/assafhazan/push-to-k8s-secrets:latest
