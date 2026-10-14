#!/bin/bash
# Step 2 (leader): configure the running container as Leader.
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
start_logging 02-configure-leader

ID=$(the_running_conjur)

if [ -z "$CONJUR_ADMIN_PASSWORD" ]; then
    read -r -s -p "Conjur admin password: " CONJUR_ADMIN_PASSWORD </dev/tty
    echo
fi

# Every name the certificate should cover - restore keeps them, so they're set once, here
ALTNAMES=$(printf '%s\n' "$(hostname -f)" "$(hostname -s)" localhost ${LEADER_ALTNAMES//,/ } \
    | awk 'NF && !seen[$0]++' | paste -sd, -)

step "Configuring Leader: hostname ${CONJUR_HOSTNAME}, account ${CONJUR_ACCOUNT}"
echo "Altnames: ${ALTNAMES}"
cm exec "$ID" evoke configure leader \
    --accept-eula \
    --hostname "$CONJUR_HOSTNAME" \
    --leader-altnames "$ALTNAMES" \
    --admin-password "$CONJUR_ADMIN_PASSWORD" \
    "$CONJUR_ACCOUNT"

step "Waiting for health"
wait_for_health
echo "Conjur is up at https://${CONJUR_HOSTNAME}"
