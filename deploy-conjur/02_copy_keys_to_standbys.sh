#!/bin/bash
#============ Variables ===============
# Internal
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/scripts.properties
#========== Script ===============
scp "$CONTAINER_VOLUME_PATH"/"$CONTAINER_NAME"_"$CONTAINER_TAG"/seeds/standby_seed.tar "$CONJUR_STANDBY_HOST_1":/tmp/
scp "$CONTAINER_VOLUME_PATH"/"$CONTAINER_NAME"_"$CONTAINER_TAG"/seeds/standby_seed.tar "$CONJUR_STANDBY_HOST_2":/tmp/

