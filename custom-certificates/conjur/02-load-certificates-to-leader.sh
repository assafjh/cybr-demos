#!/bin/bash
# This script is meant to use at the Conjur Leader VM machine.
#============ Internal ===============
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR"/.env
#============ Script ===============
FILES_TO_COPY=("$ROOT_CA_CERTIFICATE_PATH" "$LEADER_KEY_FILE_PATH" "$SERVER_CERTIFICATE_FILE_NAME")
COPY_CERTS_TO_LEADER "${FILES_TO_COPY[@]}"
