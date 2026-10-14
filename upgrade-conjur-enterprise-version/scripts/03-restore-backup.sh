#!/bin/bash
set -euo pipefail

# This script will restore a backup to a Conjur node

#================ Internal =======================
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
LOGS_FOLDER="${SCRIPT_DIR}/../logs"
BACKUPS_FOLDER="${SCRIPT_DIR}/../backup"
LOG_FILE="${LOGS_FOLDER}/03-restore-backup-$(date +%Y-%m-%d).log"

mkdir -p "${LOGS_FOLDER}"

#================ Clean Output Handler (No-Enter Fix) =======================
exec 3>&1 4>&2
cleanup() {
    local exit_code=$?
    exec 1>&3 2>&4 3>&- 4>&-
    wait "${LOG_PID:-}" 2>/dev/null || true
    exit $exit_code
}
trap cleanup EXIT

exec > >(while read -r line; do echo "$(date +'%Y-%m-%d %H:%M:%S') | $line"; done | tee -a "${LOG_FILE}") 2>&1
LOG_PID=$!

echo "[ Script started ]"

#================ Variables =======================
SUDO="${SUDO:-}"
CONTAINER_MGR="${CONTAINER_MGR:-docker}"
CONTAINER_IMG="${CONTAINER_IMG:-aws-pub-lab:5443/conjur-appliance}"
CONJUR_PORT=443

# Read version tag from command line argument ($1) or fallback to 13.10.0 default
CONTAINER_TAG="${1:-13.10.0}"
CONTAINER_NAME="conjur-${CONTAINER_TAG}"

# Nginx Host Validation Bypass Flag (true / false)
ENABLE_NGINX_BYPASS="${ENABLE_NGINX_BYPASS:-true}"

#================ Find Target Container =======================
echo "==== Locating target Conjur container (${CONTAINER_NAME}) ===="
CONTAINER_ID=$(${SUDO} ${CONTAINER_MGR} ps -q -f "name=^/${CONTAINER_NAME}$" || true)

if [ -z "${CONTAINER_ID}" ]; then
    echo "Notice: Exact container name '${CONTAINER_NAME}' not found. Searching by image tag..."
    CONTAINER_ID=$(${SUDO} ${CONTAINER_MGR} ps --filter "ancestor=${CONTAINER_IMG}:${CONTAINER_TAG}" --format "{{.ID}}" | head -n 1 || true)
fi

if [ -z "${CONTAINER_ID}" ]; then
    echo "Error: Could not find a running container for ${CONTAINER_IMG}:${CONTAINER_TAG} or name ${CONTAINER_NAME}"
    exit 1
fi
echo "Target Container ID: ${CONTAINER_ID}"

#================ Locate Backup Assets =======================
echo "==== Locating backup archive on Host ===="
BACKUP_FILE=$(find "${BACKUPS_FOLDER}" -type f -name '*.tar.xz.gpg' -exec ls -t1 {} + | head -n 1 || true)
KEY_FILE="${BACKUPS_FOLDER}/key"

if [ -z "${BACKUP_FILE}" ] || [ ! -f "${BACKUP_FILE}" ]; then
    echo "Error: No .tar.xz.gpg backup file found in ${BACKUPS_FOLDER}"
    exit 1
fi

if [ ! -f "${KEY_FILE}" ]; then
    echo "Error: Backup key file missing at ${KEY_FILE}"
    exit 1
fi

echo "Backup file to restore: ${BACKUP_FILE}"
echo "Key file identified: ${KEY_FILE}"

# Extract base filename to avoid multi-file expansion issues inside container
BACKUP_FILENAME=$(basename "${BACKUP_FILE}")

#================ Copy & Restore =======================
echo "==== Copying backup assets into Conjur container ===="
${SUDO} ${CONTAINER_MGR} cp "${BACKUP_FILE}" "${CONTAINER_ID}:/opt/conjur/backup/"
${SUDO} ${CONTAINER_MGR} cp "${KEY_FILE}" "${CONTAINER_ID}:/opt/conjur/backup/"

echo "==== Container Backup Directory Contents ===="
${SUDO} ${CONTAINER_MGR} exec "${CONTAINER_ID}" ls -ltr /opt/conjur/backup/

echo "==== Restoring Backup via Evoke ===="
${SUDO} ${CONTAINER_MGR} exec "${CONTAINER_ID}" sh -c "
    set -e
    chmod 600 /opt/conjur/backup/key
    evoke unpack backup --key /opt/conjur/backup/key \"/opt/conjur/backup/${BACKUP_FILENAME}\"
    evoke restore --accept-eula
"

#================ Optional Nginx Bypass =======================
if [ "${ENABLE_NGINX_BYPASS}" == "true" ]; then
    echo "==== Bypassing Nginx Host Validation (ENABLE_NGINX_BYPASS=true) ===="
    ${SUDO} ${CONTAINER_MGR} exec "${CONTAINER_ID}" sh -c "sed -i 's/default 0;/default 1;/g' /etc/nginx/conf.d/is_host_valid.conf && nginx -s reload"
else
    echo "==== Skipping Nginx Host Validation Bypass (ENABLE_NGINX_BYPASS=${ENABLE_NGINX_BYPASS}) ===="
fi

#================ Health Check =======================
echo "==== Performing Health Check ===="
sleep 5
curl -k "https://127.0.0.1:${CONJUR_PORT}/health" || echo "Warning: Health check endpoint returned non-200 response"

echo "[ Script finished successfully ]"
