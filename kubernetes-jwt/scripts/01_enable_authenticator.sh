#!/bin/bash
CONTAINER_ID=$(curl -s -k https://127.0.0.1:8443/info | awk '/container/ {print $2}' | tr -d '",')
podman exec -it $CONTAINER_ID evoke variable set CONJUR_AUTHENTICATORS authn,authn-jwt/k8s-cluster1