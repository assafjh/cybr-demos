#!/bin/bash
# Step 0: load a conjur-appliance image tarball and push it to the lab registry (CONTAINER_IMG).
# Usage: 00-load-image.sh <conjur-appliance_X.Y.Z.tar.gz>
set -euo pipefail
TARBALL=${1:?Usage: $0 <conjur-appliance_X.Y.Z.tar.gz>}
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
start_logging 00-load-image

[ -f "$TARBALL" ] || die "File not found: ${TARBALL}"

step "Loading ${TARBALL}"
# docker: "Loaded image: repo:tag" or "Loaded image ID: sha256:..."; podman: "Loaded image: ..." / "Loaded image(s): ..."
LOADED=$(cm load -i "$TARBALL" | sed -n 's/^Loaded image[^:]*: //p' | tail -n 1)
[ -n "$LOADED" ] || die "Could not tell which image was loaded from ${TARBALL}"

# Tag from the loaded image name, or from the file name (conjur-appliance_13.10.0.tar.gz -> 13.10.0)
LAST=${LOADED##*/}
if [[ $LOADED != sha256:* && $LAST == *:* ]]; then
    TAG=${LAST##*:}
else
    FILE=$(basename -- "$TARBALL")
    FILE=${FILE%%.tar*}
    TAG=${FILE##*_}
fi
TARGET="${CONTAINER_IMG}:${TAG}"

step "Pushing ${LOADED} as ${TARGET}"
cm tag "$LOADED" "$TARGET"
cm push "$TARGET"

echo "Ready. Next: 01-prepare-upgrade.sh, 02-deploy-new-version.sh, 03-restore-backup.sh (they pick up ${TAG})"
