#!/bin/bash
#============ Variables ===============
# Path to our safe at Conjur, leave as is
SAFE_PATH=data/jenkins/projects/safe/project
# Secret variable name, leave as is
VARIABLE_NAME=secret
# Jenkins URL with port 
JENKINS_URL=
# If needed, modify the below to configure Conjur CLI location
CONJUR_CLI=conjur
#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
"$CONJUR_CLI" whoami

# Populate safe secrets with values
for i in {1..3}
do
    for k in {1..3}
    do
        if command -p md5sum  /dev/null >/dev/null 2>&1
        then
            "$CONJUR_CLI" variable set -i "$SAFE_PATH$i/$VARIABLE_NAME$k" -v "$(echo $RANDOM | md5sum | head -c 20; echo;)"
        else
            "$CONJUR_CLI" variable set -i "$SAFE_PATH$i/$VARIABLE_NAME$k" -v "$(echo $RANDOM | md5 | head -c 20; echo;)"
        fi
    done
done

# Populate authenticator values
"$CONJUR_CLI" variable set -i conjur/authn-jwt/jenkins1/identity-path -v "/data/jenkins/projects"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/jenkins1/issuer -v "$JENKINS_URL"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/jenkins1/token-app-property -v "identity"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/jenkins1/jwks-uri -v "$JENKINS_URL/jwtauth/conjur-jwk-set"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/jenkins1/audience -v "conjur-jenkins-demo1"
