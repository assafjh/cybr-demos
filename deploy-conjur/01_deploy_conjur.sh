#!/bin/bash

set -euo pipefail

#============ Variables ===============
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/scripts.properties"

CONTAINER_FULL_NAME="${CONTAINER_NAME}_${CONTAINER_TAG}"

#========== Script ===============

# Create the volume directories Conjur requires
mkdir -p "$CONTAINER_VOLUME_PATH/$CONTAINER_FULL_NAME"/{config,security,backups,seeds,logs,certs}

# Allow rootless containers to bind to privileged ports (Podman only)
if [ -z "$SUDO" ] && [ "$(whoami)" != "root" ]; then
    sudo sysctl net.ipv4.ip_unprivileged_port_start=443
    sudo loginctl enable-linger "$(whoami)"
fi

$SUDO $CONTAINER_MGR run \
    --name "$CONTAINER_FULL_NAME" \
    --detach \
    --restart=unless-stopped \
    --security-opt seccomp=unconfined \
    --publish "${SERVER_PORT:-443}:443" \
    --publish "${LB_VERIFICATION_PORT:-444}:444" \
    --publish "${DB_PORT:-5432}:5432" \
    --publish "${AUDIT_REPLICATION_PORT:-1999}:1999" \
    --log-driver journald \
    --volume "$CONTAINER_VOLUME_PATH/$CONTAINER_FULL_NAME/config:/etc/conjur/config:Z" \
    --volume "$CONTAINER_VOLUME_PATH/$CONTAINER_FULL_NAME/security:/opt/cyberark/dap/security:Z" \
    --volume "$CONTAINER_VOLUME_PATH/$CONTAINER_FULL_NAME/backups:/opt/conjur/backup:Z" \
    --volume "$CONTAINER_VOLUME_PATH/$CONTAINER_FULL_NAME/seeds:/opt/cyberark/dap/seeds:Z" \
    --volume "$CONTAINER_VOLUME_PATH/$CONTAINER_FULL_NAME/logs:/var/log/conjur:Z" \
    "$CONTAINER_IMG:$CONTAINER_TAG"

# Optionally create a systemd service for auto-start (Podman only)
if [ "$CONTAINER_MGR" == "podman" ] && [ "$IS_CREATE_AUTO_START" == "true" ]; then
    $SUDO podman generate systemd "$CONTAINER_FULL_NAME" --name --container-prefix="" --separator="" \
        > "$SCRIPT_DIR/conjur.service"

    SYSTEMD_FOLDER=system
    SYSTEMD_FLAG=""
    if [ "$(id -u)" -ne 0 ]; then
        SYSTEMD_FOLDER=user
        SYSTEMD_FLAG=--user
    fi

    sudo mv "$SCRIPT_DIR/conjur.service" "/etc/systemd/$SYSTEMD_FOLDER/conjur.service"

    if selinuxenabled 2>/dev/null; then
        sudo /sbin/restorecon -v "/etc/systemd/$SYSTEMD_FOLDER/conjur.service"
    fi

    sudo systemctl $SYSTEMD_FLAG daemon-reload
    sudo systemctl $SYSTEMD_FLAG enable conjur
fi

