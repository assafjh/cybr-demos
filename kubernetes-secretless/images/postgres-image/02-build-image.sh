#!/bin/bash
#=======
CONTAINER_MGR=docker
#=======
"$CONTAINER_MGR" build --no-cache --tag docker.io/assafhazan/postgres-zoo-demo:v11.2 -f ./Dockerfile .
"$CONTAINER_MGR" login docker.io -u assafhazan
"$CONTAINER_MGR" push docker.io/assafhazan/postgres-zoo-demo:v11.2
