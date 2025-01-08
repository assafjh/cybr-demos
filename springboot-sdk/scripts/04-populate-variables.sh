#!/bin/bash
#============ Variables ===============
# Script path
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# If needed, modify the below to configure Conjur CLI location
CONJUR_CLI=/Applications/ConjurCloudCLI.app/Contents/Resources/conjur/conjur

# JWKS location
JWKS_FILE="$SCRIPT_DIR/../compiled/jwks.json"

#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
"$CONJUR_CLI" whoami

# Populate authenticator values
"$CONJUR_CLI" variable set -i conjur/authn-jwt/springboot1/identity-path -v "/data/springboot"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/springboot1/issuer -v "springboot-conjur-demo-app"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/springboot1/token-app-property -v "sub"

#============ JWKS ===============

# Check if the JWKS file exists
if [ ! -f "$JWKS_FILE" ]; then
    echo "Error: JWKS file not found at $JWKS_FILE"
    exit 1
fi

# Extract the JWKS key entry (entire "keys" array)
JWKS_ENTRY=$(jq '.keys[0]' "$JWKS_FILE")

# Check if the key entry is found
if [ -z "$JWKS_ENTRY" ]; then
    echo "Error: No valid key entry found in JWKS file."
    exit 1
fi

"$CONJUR_CLI" variable set -i conjur/authn-jwt/springboot1/public-keys -v "$JWKS_ENTRY"
