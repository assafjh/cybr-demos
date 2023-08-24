#!/bin/sh
#=======
CONTAINER_MGR=docker
#=======
"$CONTAINER_MGR" build --no-cache --tag docker.io/assafhazan/rest-api-conjur-auth-client-consumer:latest .
"$CONTAINER_MGR" login docker.io -u assafhazan
"$CONTAINER_MGR" push docker.io/assafhazan/rest-api-conjur-auth-client-consumer:latest
