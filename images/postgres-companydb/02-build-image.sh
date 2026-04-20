#!/bin/bash
#=======
CONTAINER_MGR=docker
IMAGE_NAME="docker.io/assafhazan/postgres-companydb:17-alpine"
#=======
"$CONTAINER_MGR" login docker.io -u assafhazan

"$CONTAINER_MGR" buildx create --use --name multiarch 2>/dev/null || "$CONTAINER_MGR" buildx use multiarch

"$CONTAINER_MGR" buildx build \
  --no-cache \
  --platform linux/amd64,linux/arm64 \
  -t "$IMAGE_NAME" \
  --push \
  .