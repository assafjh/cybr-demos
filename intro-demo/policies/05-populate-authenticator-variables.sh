#!/bin/bash
#============ Variables ===============
# Script path
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# If needed, modify the below to configure Conjur CLI location
CONJUR_CLI=/Applications/ConjurCloudCLI.app/Contents/Resources/conjur/conjur

AUTHN_NAME=conjur/authn-jwt/intro-demo-authn

#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
"$CONJUR_CLI" whoami

# Populate authenticator values
"$CONJUR_CLI" variable set -i ${AUTHN_NAME}/identity-path -v "/data/intro-demo/apps"
"$CONJUR_CLI" variable set -i ${AUTHN_NAME}/issuer -v "https://cognito-idp.eu-west-2.amazonaws.com/eu-west-2_fDn0jCiEv"
"$CONJUR_CLI" variable set -i ${AUTHN_NAME}/token-app-property -v "app_id"
"$CONJUR_CLI" variable set -i ${AUTHN_NAME}/jwks-uri -v "https://cognito-idp.eu-west-2.amazonaws.com/eu-west-2_fDn0jCiEv/.well-known/jwks.json"
"$CONJUR_CLI" variable set -i ${AUTHN_NAME}/enforced-claims -v "client_id"