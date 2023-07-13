#!/bin/bash
#============ Variables ===============
# Path to our safe at Conjur, leave as is
SAFE_PATH=data/kubernetes/applications/safe/
# If need conjur certificate ready for the manifest set as true
SHOULD_PREP_CONJUR_CERTIFICATE=true
CONJUR_CERTIFICATE_FILE_LOCATION="$HOME"/conjur-server.pem
# If needed, modify the below to configure Conjur CLI location
CONJUR_CLI=conjur
#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
"$CONJUR_CLI" whoami

# Populate safe secrets with values
for i in {1..8}
do
   if command -p md5sum  /dev/null >/dev/null 2>&1
    then
        "$CONJUR_CLI" variable set -i "${SAFE_PATH}secret$i" -v "$(echo $RANDOM | md5sum | head -c 20; echo;)"
    else
        "$CONJUR_CLI" variable set -i "${SAFE_PATH}secret$i" -v "$(echo $RANDOM | md5 | head -c 20; echo;)"
    fi
done

# If enabled, creating one liner b64 encoded cert 
if [ "${SHOULD_PREP_CONJUR_CERTIFICATE}" == "true" ]; then
    if command -p base64 -i "$CONJUR_CERTIFICATE_FILE_LOCATION" -w 0 > /dev/null 2>&1
    then
        base64 -i "$CONJUR_CERTIFICATE_FILE_LOCATION" -w 0 > one-line-conjur-cert.b64
    else
        base64 -i "$CONJUR_CERTIFICATE_FILE_LOCATION" -b 0 > one-line-conjur-cert.b64
    fi
echo "Conjur certificate was saved to one-line-conjur-cert.b64"
fi