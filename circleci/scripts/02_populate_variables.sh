#!/bin/bash
#============ Variables ===============
# Path to our safe at Conjur, leave as is
SAFE_PATH=circleci/apps/safe/secret
# CircleCI Organization ID
CIRCLECI_ORG_ID=
#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
conjur whoami

# Populate safe secrets with values
for i in {1..3}
do
   if command -p md5sum  /dev/null >/dev/null 2>&1
    then
        conjur variable set -i "$SAFE_PATH$i" -v "$(echo $RANDOM | md5sum | head -c 20; echo;)"
    else
        conjur variable set -i "$SAFE_PATH$i" -v "$(echo $RANDOM | md5 | head -c 20; echo;)"
    fi
done

# Populate authenticator values
conjur variable set -i conjur/authn-jwt/circleci1/issuer -v "https://oidc.circleci.com/org/$CIRCLECI_ORG_ID"
conjur variable set -i conjur/authn-jwt/circleci1/jwks-uri -v "https://oidc.circleci.com/org/$CIRCLECI_ORG_ID/.well-known/jwks-pub.json"
conjur variable set -i conjur/authn-jwt/circleci1/token-app-property -v "sub"
conjur variable set -i conjur/authn-jwt/circleci1/audience -v "$CIRCLECI_ORG_ID"
conjur variable set -i conjur/authn-jwt/circleci1/identity-path -v "/circleci/apps"
