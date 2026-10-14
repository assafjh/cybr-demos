#!/bin/bash
set -euo pipefail

# This script will prepare Conjur Enterprise for upgrade
# Do note that it is assumed Conjur Enterprise is not configured with auto-failover.

#================ Internal =======================
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
LOGS_FOLDER="${SCRIPT_DIR}/../logs"
BACKUPS_FOLDER="${SCRIPT_DIR}/../backup"
LOG_FILE="${LOGS_FOLDER}/01-prepare-upgrade-$(date +%Y-%m-%d).log"

mkdir -p "${LOGS_FOLDER}" "${BACKUPS_FOLDER}"

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
CONJUR_PORT=443

# Dynamic retrieval via Conjur /info endpoint
echo "==== Querying Conjur Info API on port ${CONJUR_PORT} ===="
INFO_JSON=$(curl -s -k "https://127.0.0.1:${CONJUR_PORT}/info" || true)

if [ -z "${INFO_JSON}" ]; then
    echo "Error: Unable to connect to Conjur API at https://127.0.0.1:${CONJUR_PORT}/info"
    exit 1
fi

CONTAINER_ID=$(echo "${INFO_JSON}" | awk '/container/ {print $2}' | tr -d '",')
CONJUR_VERSION=$(echo "${INFO_JSON}" | awk '/release/ {print $2}' | tr -d '",')

if [ -z "${CONTAINER_ID}" ]; then
    echo "Error: Failed to extract container ID from Conjur /info"
    exit 1
fi

CONTAINER_BACKUP_NAME="CONJUR-v${CONJUR_VERSION}-$(date +%Y-%m-%d-%s)"

echo "==== Found Running Container ID: ${CONTAINER_ID} (Version: ${CONJUR_VERSION}) ===="

#================ Script Execution =======================
echo "==== Disabling Conjur Node ===="
${SUDO} ${CONTAINER_MGR} exec "${CONTAINER_ID}" sv stop conjur || true

echo "==== Stopping replication on Standbys and Followers ===="
${SUDO} ${CONTAINER_MGR} exec "${CONTAINER_ID}" evoke replication stop || true

echo "==== Backing up Node ===="
${SUDO} ${CONTAINER_MGR} exec "${CONTAINER_ID}" evoke backup

echo "==== Locating backup file inside container ===="
BACKUP_FILE=$(${SUDO} ${CONTAINER_MGR} exec "${CONTAINER_ID}" find /opt/conjur/backup/ -type f -name '*.tar.xz.gpg' -exec ls -t1 {} + | head -n 1)

if [ -z "${BACKUP_FILE}" ]; then
    echo "Error: No backup file found in /opt/conjur/backup/"
    exit 1
fi

echo "Backup file identified: ${BACKUP_FILE}"

echo "==== Copying backup assets to Host (${BACKUPS_FOLDER}) ===="
${SUDO} ${CONTAINER_MGR} cp "${CONTAINER_ID}:${BACKUP_FILE}" "${BACKUPS_FOLDER}/"
${SUDO} ${CONTAINER_MGR} cp "${CONTAINER_ID}:/opt/conjur/backup/key" "${BACKUPS_FOLDER}/"

# Enforce secure file permissions on host key
chmod 600 "${BACKUPS_FOLDER}/key"

echo "==== Current Backup Directory Contents ===="
ls -ltr "${BACKUPS_FOLDER}"/*

echo "==== Stopping Conjur Container ===="
${SUDO} ${CONTAINER_MGR} stop "${CONTAINER_ID}"

echo "==== Renaming Conjur Container to ${CONTAINER_BACKUP_NAME} ===="
${SUDO} ${CONTAINER_MGR} rename "${CONTAINER_ID}" "${CONTAINER_BACKUP_NAME}"

echo "[ Script finished successfully ]"
