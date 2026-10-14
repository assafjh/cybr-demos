#!/bin/bash
# Shared settings and helpers - sourced by the step scripts.

shopt -s inherit_errexit  # make set -e apply inside $(...) too, so helper failures aren't swallowed

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(dirname -- "$SCRIPT_DIR")"
source "$SCRIPT_DIR/deploy.properties"
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

# Highest version of CONTAINER_IMG available locally (what 00-load-image.sh just loaded)
latest_local_tag() {
    cm images --format '{{.Tag}}' "$CONTAINER_IMG" | awk '$0 != "<none>" && $0 != "latest"' | sort -V | tail -n 1
}

#================ Podman =======================
# Podman has no daemon, so --restart does nothing after a reboot. As in the CyberArk docs,
# a systemd unit (conjur.service) runs the container. The upgrade scripts repoint it per version.

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

#================ Health =======================

# Ask for /health by CONJUR_HOSTNAME (resolved to this machine) so nginx host validation accepts it
wait_for_health() {
    local deadline=$((SECONDS + 180)) code
    until code=$(curl -sk -o /dev/null -w '%{http_code}' --resolve "${CONJUR_HOSTNAME}:443:127.0.0.1" \
            "https://${CONJUR_HOSTNAME}/health"); [ "$code" = "200" ]; do
        [ "$SECONDS" -lt "$deadline" ] || die "Health check did not return 200 within 3 minutes (last: ${code})"
        sleep 5
    done
    echo "Health check OK"
}
