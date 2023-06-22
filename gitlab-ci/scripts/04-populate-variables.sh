#!/bin/bash
#============ Variables ===============
# Path to our safe at Conjur, leave as is
SAFE_PATH=data/gitlab/ci/safe/secret
# GitLab Issuer - usually GitLab server hostname
GITLAB_ISSUER=
# GitLab URL
GITLAB_URL=
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
"$CONJUR_CLI" variable set -i conjur/authn-jwt/gitlab1/issuer -v "$GITLAB_ISSUER"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/gitlab1/jwks-uri -v "$GITLAB_URL/-/jwks/"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/gitlab1/token-app-property -v "namespace_path"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/gitlab1/enforced-claims -v "ref,ref_type"
"$CONJUR_CLI" variable set -i conjur/authn-jwt/gitlab1/identity-path -v "/data/gitlab/ci"
