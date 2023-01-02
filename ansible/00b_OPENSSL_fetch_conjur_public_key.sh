#!/bin/bash
#============ Variables ===============
# Internal
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/conjur_env.properties
#========== Script ===============
[ ! -d "$SCRIPT_DIR/certs" ] && mkdir $SCRIPT_DIR/certs
echo "Saving Conjur public key to file: $SCRIPT_DIR/certs/conjur-public-key.pem"
openssl s_client -showcerts -connect $CONJUR_FQDN:443 < /dev/null 2> /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "$SCRIPT_DIR"/certs/conjur-public-key.pem
