#!/bin/bash

# This script will:
# 1. Authenticate to PCloud
# 2. Use PCloud token to authenticate against Conjur Cloud
# 3. Will retrieve a variable from Conjur Cloud

#======== Variables ===========
identity_tenant_name=
conjur_tenant_name=
username=
password=
# Slashes should be url encoded - / = %2F 
# Example: data/app/safe/secret1 -> data%2Fapp%2Fsafe%2Fsecret1
conjur_variable_path=

#========= Script ===========

# Checking that JQ is installed
if ! command -v jq &> /dev/null
then
    echo "Please install JQ and re-run the script"
    exit 1
fi


# Initiating PCloud Login
response=$(curl -s --request POST \
     --url https://"$identity_tenant_name".id.cyberark.cloud/Security/StartAuthentication \
     --header 'accept: */*' \
     --header 'content-type: application/json' \
     --data "{\"Version\": \"1.0\", \"User\": \"$username\"}")

# Retreiving parameters in order to initiate challenge
SessionId=$(jq -r '.Result.SessionId' <<< "${response}")
MechanismId=$(jq -r '.Result.Challenges[0].Mechanisms[0].MechanismId' <<< "${response}")

# Completing Challenge
identity_token=$(curl -s --request POST \
     --url https://"$identity_tenant_name".id.cyberark.cloud/Security/AdvanceAuthentication \
     --header 'accept: */*' \
     --header 'content-type: application/json' \
     --data "{\"Action\": \"Answer\",\"SessionId\": \"$SessionId\",\"MechanismId\": \"$MechanismId\",\"Answer\": \"$password\"}" | jq -r '.Result.Token')

# Authenticating to Conjur
conjur_token=$(curl -s --request POST "https://$conjur_tenant_name.secretsmgr.cyberark.cloud/api/authn-oidc/cyberark/conjur/authenticate" \
     --header 'Accept-Encoding: base64' \
     --header 'Content-Type: application/x-www-form-urlencoded' \
     --data-urlencode "id_token=$identity_token")

# Retriving variable from Conjur
conjur_variable_value=$(curl -s --request GET "https://$conjur_tenant_name.secretsmgr.cyberark.cloud/api/secrets/conjur/variable/$conjur_variable_path" \
         --header "Authorization: Token token=\"$conjur_token\"")

# Print the variable path and value
printf "=================\nVariable Path: %s\n\nVariable value: %s\n=================\n" "$conjur_variable_path" "$conjur_variable_value"