#!/bin/bash
# Builds and pushes the unified rest-api-app image to GHCR.
# AUTH_MODE is selected at runtime via env var — one image supports both modes.

CONTAINER_MGR="${CONTAINER_MGR:-docker}"
REGISTRY="ghcr.io/assafjh"
IMAGE="rest-api-app"

"$CONTAINER_MGR" build --no-cache --tag "$REGISTRY/$IMAGE:latest" .
"$CONTAINER_MGR" push "$REGISTRY/$IMAGE:latest"
