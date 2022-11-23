#!/bin/bash
#============ Variables ===============
# Path to our safe at Conjur, leave as is
SAFE_PATH=github/apps/safe/secret
#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
conjur whoami

# Populate safe secrets with values
for i in {1..3}
do
   if command -p md5sum  >/dev/null 2>&1
    then
        conjur variable set -i "$SAFE_PATH$i" -v "$(echo $RANDOM | md5sum | head -c 20; echo;)"
    else
        conjur variable set -i "$SAFE_PATH$i" -v "$(echo $RANDOM | md5 | head -c 20; echo;)"
    fi
done

# Populate authenticator values
conjur variable set -i conjur/authn-jwt/github1/issuer -v "https://token.actions.githubusercontent.com"
conjur variable set -i conjur/authn-jwt/github1/jwks-uri -v "https://token.actions.githubusercontent.com/.well-known/jwks"
conjur variable set -i conjur/authn-jwt/github1/token-app-property -v "workflow"
conjur variable set -i conjur/authn-jwt/github1/enforced-claims -v "workflow,repository"
conjur variable set -i conjur/authn-jwt/github1/identity-path -v "/github/apps"
