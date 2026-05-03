#!/bin/bash

set -euo pipefail

#============ Variables ===============
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/scripts.properties"

CONTAINER_FULL_NAME="${CONTAINER_NAME}_${CONTAINER_TAG}"

#========== Script ===============

# Configure the container as a Conjur Enterprise Leader
$SUDO $CONTAINER_MGR exec "$CONTAINER_FULL_NAME" evoke configure master \
    --accept-eula \
    --hostname "$(hostname -f)" \
    --master-altnames "$MASTER_ALTNAMES" \
    --admin-password "$CONJUR_ADM_PWD" \
    "$CONJUR_ORG"

# Generate a standby seed file so standbys can join the cluster
$SUDO $CONTAINER_MGR exec "$CONTAINER_FULL_NAME" evoke seed standby \
    > "$CONTAINER_VOLUME_PATH/$CONTAINER_FULL_NAME/seeds/standby_seed.tar"

