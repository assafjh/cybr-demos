#!/bin/bash
# Step 2: start a fresh, role-less Conjur container on the new version.
# Usage: 02-deploy-new-version.sh [version-tag]   (default: highest local version of CONTAINER_IMG)
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
start_logging 02-deploy-new-version

TAG=${1:-$(latest_local_tag)}
[ -n "$TAG" ] || die "No local ${CONTAINER_IMG} image - run 00-load-image.sh or pass a tag"
echo "Version: ${TAG}"

NAME="${CONTAINER_NAME}-${TAG}"
IMAGE="${CONTAINER_IMG}:${TAG}"
DIR="${CONTAINER_VOLUME_PATH}/${NAME}"

mkdir -p "$DIR"/{config,security,backups,seeds,logs}

# Use the seccomp profile shipped in the image, so each version gets the one it was built for
step "Extracting seccomp profile from ${IMAGE}"
if cm run --rm --entrypoint /bin/cat "$IMAGE" /usr/share/doc/conjur/examples/seccomp.json > "$DIR/security/seccomp.json"; then
    SECCOMP="seccomp=${DIR}/security/seccomp.json"
else
    echo "No profile in image - running unconfined"
    rm -f "$DIR/security/seccomp.json"
    SECCOMP="seccomp=unconfined"
fi

# Docker restarts the container itself; with Podman, systemd does (see common.sh)
RESTART=unless-stopped
if is_podman; then
    RESTART=no
    # Rootless Podman can't bind port 443 by default - persist it so it survives reboots
    if [ -z "$SUDO" ] && [ "$(id -u)" -ne 0 ]; then
        echo "net.ipv4.ip_unprivileged_port_start=443" | sudo tee /etc/sysctl.d/99-conjur.conf >/dev/null
        sudo sysctl --quiet --system
        sudo loginctl enable-linger "$(whoami)"
    fi
fi

step "Starting ${NAME}"
cm run \
    --name "$NAME" \
    --detach \
    --restart="$RESTART" \
    --security-opt "$SECCOMP" \
    --publish 443:443 \
    --publish 444:444 \
    --publish 5432:5432 \
    --publish 1999:1999 \
    --log-driver journald \
    --volume "$DIR/config:/etc/conjur/config:Z" \
    --volume "$DIR/security:/opt/cyberark/dap/security:Z" \
    --volume "$DIR/backups:/opt/conjur/backup:Z" \
    --volume "$DIR/seeds:/opt/cyberark/dap/seeds:Z" \
    --volume "$DIR/logs:/var/log/conjur:Z" \
    "$IMAGE"

podman_install_unit "$NAME"
