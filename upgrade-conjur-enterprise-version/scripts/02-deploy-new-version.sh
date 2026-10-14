#!/bin/bash
set -euo pipefail

# This script will deploy a new role-less Conjur node

#================ Internal =======================
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
LOGS_FOLDER="${SCRIPT_DIR}/../logs"
LOG_FILE="${LOGS_FOLDER}/02-deploy-new-version-$(date +%Y-%m-%d).log"

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
CONTAINER_NAME="conjur"

# Read version tag from command line argument ($1) or fallback to 13.10.0 default
CONTAINER_TAG="${1:-13.10.0}"

CONTAINER_VOLUME_PATH="${HOME}/conjur"
IS_CREATE_AUTO_START=false

SERVER_PORT=443
LB_VERIFICATION_PORT=444
DB_PORT=5432
AUDIT_REPLICATION_PORT=1999

TARGET_DIR="${CONTAINER_VOLUME_PATH}/${CONTAINER_NAME}-${CONTAINER_TAG}"

echo "==== Preparing Conjur node deployment for tag: ${CONTAINER_TAG} ===="

# Create directory structure
mkdir -p "${TARGET_DIR}"/{config,security,backups,seeds,logs,certs}

# Copy seccomp configuration if present
SECCOMP_OPT=""
if [ -f "${SCRIPT_DIR}/seccomp.json" ]; then
    cp -v "${SCRIPT_DIR}/seccomp.json" "${TARGET_DIR}/security/"
    SECCOMP_OPT="--security-opt seccomp=${TARGET_DIR}/security/seccomp.json"
else
    echo "Warning: seccomp.json not found in ${SCRIPT_DIR}. Proceeding without seccomp profile..."
fi

# Enable unprivileged port binding for non-root users
if [ -z "${SUDO}" ] && [ "$(id -u)" -ne 0 ]; then
    echo "Enabling usage of port 443 on non-root user..."
    sudo sysctl net.ipv4.ip_unprivileged_port_start=443
    echo "Enabling linger for non-root user..."
    sudo loginctl enable-linger "$(whoami)"
fi

#================ Deploy Container =======================
echo "==== Deploying Conjur container (${CONTAINER_NAME}-${CONTAINER_TAG}) ===="

${SUDO} ${CONTAINER_MGR} run \
    --name "${CONTAINER_NAME}-${CONTAINER_TAG}" \
    --detach \
    --restart=unless-stopped \
    ${SECCOMP_OPT} \
    --publish "${SERVER_PORT}:443" \
    --publish "${LB_VERIFICATION_PORT}:444" \
    --publish "${DB_PORT}:5432" \
    --publish "${AUDIT_REPLICATION_PORT}:1999" \
    --log-driver journald \
    --volume "${TARGET_DIR}/config:/etc/conjur/config:Z" \
    --volume "${TARGET_DIR}/security:/opt/cyberark/dap/security:Z" \
    --volume "${TARGET_DIR}/backups:/opt/conjur/backup:Z" \
    --volume "${TARGET_DIR}/seeds:/opt/cyberark/dap/seeds:Z" \
    --volume "${TARGET_DIR}/logs:/var/log/conjur:Z" \
    "${CONTAINER_IMG}:${CONTAINER_TAG}"

#================ Podman Auto-Start (Optional) =======================
if [ "${CONTAINER_MGR}" == "podman" ] && [ "${IS_CREATE_AUTO_START}" == "true" ]; then
    echo "Enabling auto start for podman container..."

    if [ "$(id -u)" -eq 0 ]; then
        SYSTEMD_DIR="/etc/systemd/system"
        SYSTEMD_FLAG=""
    else
        SYSTEMD_DIR="${HOME}/.config/systemd/user"
        SYSTEMD_FLAG="--user"
        mkdir -p "${SYSTEMD_DIR}"
    fi

    ${SUDO} podman generate systemd "${CONTAINER_NAME}-${CONTAINER_TAG}" --name --container-prefix="" --separator="" > "${SCRIPT_DIR}/conjur.service"
    mv "${SCRIPT_DIR}/conjur.service" "${SYSTEMD_DIR}/conjur.service"

    if command -v selinuxenabled >/dev/null 2>&1 && selinuxenabled; then
        restorecon -v "${SYSTEMD_DIR}/conjur.service" || true
    fi

    systemctl ${SYSTEMD_FLAG} daemon-reload
    systemctl ${SYSTEMD_FLAG} enable conjur
fi

echo "[ Script finished successfully ]"
