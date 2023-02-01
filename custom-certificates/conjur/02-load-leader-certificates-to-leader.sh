#!/bin/bash
# This script is meant to use at the Conjur Leader VM machine.
#============ Internal ===============
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR"/.env
#============ Script ===============
FILES_TO_COPY=("$ROOT_CA_CERTIFICATE_PATH" "$LEADER_KEY_FILE_PATH" "$LEADER_CERTIFICATE_FILE_PATH")
COPY_CERTS_TO_LEADER "${FILES_TO_COPY[@]}"

$SUDO $CONTAINER_MGR exec $CONTAINER_ID evoke ca import --no-restart --force --root /certs/$(basename $ROOT_CA_CERTIFICATE_PATH)
$SUDO $CONTAINER_MGR exec $CONTAINER_ID evoke ca import --key /certs/$(basename $LEADER_KEY_FILE_PATH) --set /certs/$(basename $LEADER_CERTIFICATE_FILE_PATH)

