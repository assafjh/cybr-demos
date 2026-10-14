#!/bin/bash
# Step 1: back up the running Conjur node, then stop it and park it as <name>-<version>-pre-upgrade-<timestamp>.
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
start_logging 01-prepare-upgrade

ID=$(the_running_conjur)
VERSION=$(container_tag "$ID")
STAMP=$(date +%F-%H%M%S)
BACKUP_DIR="${BACKUPS_DIR}/${STAMP}_v${VERSION}"
PARKED="${CONTAINER_NAME}-${VERSION}-pre-upgrade-${STAMP}"

step "Backing up Conjur ${VERSION} (${ID})"
cm exec "$ID" sv stop conjur
cm exec "$ID" evoke backup
ARCHIVE=$(cm exec "$ID" sh -c 'ls -t /opt/conjur/backup/*.tar.xz.gpg | head -n 1')

step "Copying backup to ${BACKUP_DIR}"
mkdir -p "$BACKUP_DIR"
cm cp "${ID}:${ARCHIVE}" "$BACKUP_DIR/"
cm cp "${ID}:/opt/conjur/backup/key" "$BACKUP_DIR/"
${SUDO} chmod 600 "$BACKUP_DIR"/*
ls -l "$BACKUP_DIR"

step "Stopping and parking container as ${PARKED}"
podman_disable_unit
cm stop "$ID"
cm rename "$ID" "$PARKED"
