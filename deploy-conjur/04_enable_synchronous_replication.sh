#!/bin/bash -x
#============ Variables ===============
# Internal
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/scripts.properties
#========== Script ===============
$SUDO $CONTAINER_MGR exec "$CONTAINER_NAME"_"$CONTAINER_TAG" evoke replication sync start

