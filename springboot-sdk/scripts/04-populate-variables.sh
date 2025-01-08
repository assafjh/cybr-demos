#!/bin/bash
#============ Variables ===============
# If needed, modify the below to configure Conjur CLI location
CONJUR_CLI=/Applications/ConjurCloudCLI.app/Contents/Resources/conjur/conjur

#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
"$CONJUR_CLI" whoami

# Populate authenticator values
"$CONJUR_CLI" variable set -i conjur/authn-jwt/springboot1/identity-path -v "/data/springboot"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/springboot1/issuer -v "springboot-conjur-demo-app"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/springboot1/token-app-property -v "sub"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/springboot1/jwks-uri -v "http://18.175.89.69:9090/.well-known/jwks.json"
