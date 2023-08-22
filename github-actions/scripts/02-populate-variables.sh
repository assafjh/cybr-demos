#!/bin/bash
#============ Variables ===============
# Path to our safe at Conjur, leave as is
SAFE_PATH=data/github/apps/safe/secret
# If needed, modify the below to configure Conjur CLI location
CONJUR_CLI=conjur
#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
"$CONJUR_CLI" whoami

# Populate safe secrets with values
for i in {1..3}
do
   if command -p md5sum  /dev/null >/dev/null 2>&1
    then
        "$CONJUR_CLI" variable set -i "$SAFE_PATH$i" -v "$(echo $RANDOM | md5sum | head -c 20; echo;)"
    else
        "$CONJUR_CLI" variable set -i "$SAFE_PATH$i" -v "$(echo $RANDOM | md5 | head -c 20; echo;)"
    fi
done

# Populate authenticator values
"$CONJUR_CLI" variable set -i conjur/authn-jwt/github1/issuer -v "https://token.actions.githubusercontent.com"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/github1/jwks-uri -v "https://token.actions.githubusercontent.com/.well-known/jwks"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/github1/token-app-property -v "workflow"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/github1/enforced-claims -v "workflow,repository"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/github1/identity-path -v "/data/github/apps"
