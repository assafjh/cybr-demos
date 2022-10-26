#!/bin/bash
#============ Variables ===============
# Internal
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/scripts.properties
#========== Script ===============
$SUDO $CONTAINER_MGR exec "$CONTAINER_NAME"_"$CONTAINER_TAG" evoke configure master \
  --accept-eula \
  --hostname $(hostname -f) \
  --master-altnames "$MASTER_ALTNAMES" \
  --admin-password "$CONJUR_ADM_PWD" \
  "$CONJUR_ORG"

$SUDO $CONTAINER_MGR exec "$CONTAINER_NAME"_"$CONTAINER_TAG" evoke seed standby > "$CONTAINER_VOLUME_PATH"/"$CONTAINER_NAME"_"$CONTAINER_TAG"/seeds/standby_seed.tar

