#!/bin/bash
#============ Variables ===============
# Internal
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/scripts.properties
#========== Script ===============
mv -v /tmp/standby_seed.tar "$CONTAINER_VOLUME_PATH"/"$CONTAINER_NAME"_"$CONTAINER_TAG"/seeds/standby_seed.tar
mv -v /tmp/master.key "$CONTAINER_VOLUME_PATH"/"$CONTAINER_NAME"_"$CONTAINER_TAG"/secrets/master.key

$SUDO $CONTAINER_MGR exec "$CONTAINER_NAME"_"$CONTAINER_TAG" evoke unpack seed /opt/cyberark/dap/seeds/standby_seed.tar
$SUDO $CONTAINER_MGR exec "$CONTAINER_NAME"_"$CONTAINER_TAG" evoke keys exec evoke configure standby

