#!/bin/bash
# Step 3: restore the latest backup into the new container and wait for it to be healthy.
# Usage: 03-restore-backup.sh [version-tag]   (default: the running Conjur container, i.e. the one 02 started)
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
start_logging 03-restore-backup

if [ -n "${1:-}" ]; then
    TAG=$1
else
    ID=$(the_running_conjur)
    TAG=$(container_tag "$ID")
fi
NAME="${CONTAINER_NAME}-${TAG}"
echo "Version: ${TAG}"
BACKUP_DIR=$(ls -td "$BACKUPS_DIR"/*/ 2>/dev/null | head -n 1 || true)
[ -n "$BACKUP_DIR" ] || die "No backup in ${BACKUPS_DIR} - run 01-prepare-upgrade.sh first"
ARCHIVE=$(cd "$BACKUP_DIR" && ls *.tar.xz.gpg 2>/dev/null || true)
[ -n "$ARCHIVE" ] || die "No backup archive in ${BACKUP_DIR}"

step "Restoring ${BACKUP_DIR}${ARCHIVE} into ${NAME}"
cm cp "${BACKUP_DIR}${ARCHIVE}" "${NAME}:/opt/conjur/backup/"
cm cp "${BACKUP_DIR}key" "${NAME}:/opt/conjur/backup/key"
cm exec "$NAME" sh -c "set -e
    chmod 600 /opt/conjur/backup/key
    evoke unpack backup --key /opt/conjur/backup/key /opt/conjur/backup/${ARCHIVE}
    evoke restore --accept-eula"

# Restore brings back the hostname/altnames from the node's original configure (years and many
# upgrades ago). Nginx host validation stays pinned to them - conjur.yml, env params and a new
# custom cert don't change it - so on demo nodes accept any Host header. Verified so that a
# change to this file in a future image fails loudly.
if [ "$ENABLE_NGINX_BYPASS" = "true" ]; then
    step "Disabling nginx host validation"
    CONF=/etc/nginx/conf.d/is_host_valid.conf
    cm exec "$NAME" sh -c "sed -i 's/default 0;/default 1;/' $CONF && grep -q 'default 1;' $CONF && nginx -s reload" \
        || die "nginx bypass failed - check ${CONF} in the new image"
fi

step "Waiting for health"
wait_for_health
echo "Old container is kept stopped - remove it once you're happy:"
cm ps -a --format '{{.Names}}' | grep -- '-pre-upgrade-' | sed "s/^/  ${SUDO:+$SUDO }${CONTAINER_MGR} rm /"
