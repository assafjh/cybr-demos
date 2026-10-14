#!/bin/bash
# Shared settings and helpers - sourced by the step scripts.

shopt -s inherit_errexit  # make set -e apply inside $(...) too, so helper failures aren't swallowed

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/upgrade.properties"
BACKUPS_DIR="$ROOT_DIR/backup"
LOGS_DIR="$ROOT_DIR/logs"

cm()   { ${SUDO} ${CONTAINER_MGR} "$@"; }
step() { echo "==== $* ===="; }
die()  { echo "ERROR: $*" >&2; exit 1; }

# Mirror all output to logs/<name>-<timestamp>.log; wait for tee on exit so the prompt doesn't come back early
start_logging() {
    mkdir -p "$LOGS_DIR"
    exec > >(tee -a "$LOGS_DIR/$1-$(date +%F-%H%M%S).log") 2>&1
    LOG_PID=$!
    trap 'exec >&- 2>&-; wait $LOG_PID' EXIT
}

# Running containers built from CONTAINER_IMG (any tag)
running_conjur() {
    cm ps --format '{{.ID}} {{.Image}}' | awk -v img="${CONTAINER_IMG##*/}" 'index($2, img) { print $1 }'
}

# The single running Conjur container
the_running_conjur() {
    local id
    id=$(running_conjur)
    [ "$(wc -w <<<"$id")" -eq 1 ] || die "Expected exactly one running Conjur container, found: ${id:-none}"
    echo "$id"
}

# Version tag of a container's image
container_tag() {
    local image
    image=$(cm inspect --format '{{.Config.Image}}' "$1")
    echo "${image##*:}"
}

# Highest version of CONTAINER_IMG available locally (what 00-load-image.sh just loaded)
latest_local_tag() {
    cm images --format '{{.Tag}}' "$CONTAINER_IMG" | awk '$0 != "<none>" && $0 != "latest"' | sort -V | tail -n 1
}

#================ Podman =======================
# Podman has no daemon, so --restart does nothing after a reboot. As in the CyberArk upgrade
# docs, a systemd unit (conjur.service) runs the current container and is regenerated per upgrade.

is_podman() { [ "${CONTAINER_MGR##*/}" = "podman" ]; }

# Rootful (sudo/root) -> system unit, rootless -> user unit
podman_systemctl() {
    if [ -n "$SUDO" ] || [ "$(id -u)" -eq 0 ]; then sudo systemctl "$@"; else systemctl --user "$@"; fi
}

podman_install_unit() {
    local name=$1 dir=/etc/systemd/system
    is_podman || return 0
    [ -n "$SUDO" ] || [ "$(id -u)" -eq 0 ] || dir="$HOME/.config/systemd/user"
    step "Pointing conjur.service at ${name}"
    ${SUDO} mkdir -p "$dir"
    cm generate systemd --name "$name" --container-prefix="" --separator="" | ${SUDO} tee "$dir/conjur.service" >/dev/null
    podman_systemctl daemon-reload
    podman_systemctl enable conjur
}

# Stop through systemd first, so it doesn't restart the container we're parking
podman_disable_unit() {
    is_podman || return 0
    podman_systemctl stop conjur 2>/dev/null || true
    podman_systemctl disable conjur 2>/dev/null || true
}

#================ Health =======================

wait_for_health() {
    local deadline=$((SECONDS + 180)) code
    until code=$(curl -sk -o /dev/null -w '%{http_code}' https://127.0.0.1/health); [ "$code" = "200" ]; do
        [ "$SECONDS" -lt "$deadline" ] || die "Health check did not return 200 within 3 minutes (last: ${code})"
        sleep 5
    done
    echo "Health check OK"
}
