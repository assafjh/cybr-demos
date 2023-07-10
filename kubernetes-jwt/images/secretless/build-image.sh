#!/bin/bash
#=======
CONTAINER_MGR=docker
#=======
"$CONTAINER_MGR" build --no-cache --tag docker.io/assafhazan/postgres-secretless-demo:latest .
"$CONTAINER_MGR" login docker.io -u assafhazan
"$CONTAINER_MGR" push docker.io/assafhazan/postgres-secretless-demo:latest
