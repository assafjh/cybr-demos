#!/bin/bash

set -euo pipefail

#============ Variables ===============
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/scripts.properties"

CONTAINER_FULL_NAME="${CONTAINER_NAME}_${CONTAINER_TAG}"

#========== Script ===============

# Enable synchronous replication between Leader and Standbys
$SUDO $CONTAINER_MGR exec "$CONTAINER_FULL_NAME" evoke replication sync start

