#!/bin/bash
# Undo an upgrade: stop the new container and bring back the most recently parked one.
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
start_logging rollback

# Newest parked container, by the timestamp in its name
PARKED=$(cm ps -a --format '{{.Names}}' | awk -F'-pre-upgrade-' 'NF > 1 { print $2, $0 }' \
    | sort | tail -n 1 | cut -d' ' -f2)
[ -n "$PARKED" ] || die "No *-pre-upgrade-* container found"
ORIGINAL=${PARKED%-pre-upgrade-*}

podman_disable_unit
for id in $(running_conjur); do
    step "Stopping running Conjur container ${id}"
    cm stop "$id"
done

step "Restoring ${PARKED} as ${ORIGINAL}"
cm rename "$PARKED" "$ORIGINAL"
cm start "$ORIGINAL"
podman_install_unit "$ORIGINAL"
wait_for_health
echo "The stopped new-version container is kept - remove it before re-running 02 with the same tag."
