#!/bin/bash

# This script will:
# If Conjur Enterprise
#   1. Authenticate to Conjur using the API Key
#   2. Set a variable at Conjur Enterprise
# If Conjur Cloud:
#   1. Authenticate to PCloud
#   2. Use PCloud token to authenticate against Conjur Cloud
#   3. Set a variable at Conjur Cloud

#======== Variables ===========
# Script path
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Conjur Cloud variables
is_conjur_cloud=false
identity_tenant_name=

# General variables
conjur_url=
# if Conjur Cloud leave as is
conjur_account=conjur

username=kubernetes-admin01
password=

# Slashes should be url encoded - / = %2F 
# Example: root/app/safe/secret1 -> root%2Fapp%2Fsafe%2Fsecret1
conjur_variable_path=data%2Fkubernetes%2Fapplications%2Fsafe%2Fmessenger

#======== Script ===========
if [ "$is_conjur_cloud" == "true" ]; then
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
    token=$(curl -s --request POST "$conjur_url/authn-oidc/cyberark/conjur/authenticate" \
        --header 'Accept-Encoding: base64' \
        --header 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode "id_token=$identity_token")

else
    # Login to Conjur, get an API Key
    api_key=$(curl -k -s -X GET -u "$username:$password" "$conjur_url/authn/$conjur_account/login")
    # Authenticate to conjur, get a temporary token
    token=$(curl -s -k --header "Accept-Encoding: base64" --data "$api_key" "$conjur_url/authn/$conjur_account/$username/authenticate")
fi

# Using the temporary token, setting a variable in Conjur
curl -k --header "Authorization: Token token=\"$token\"" "$conjur_url/secrets/$conjur_account/variable/$conjur_variable_path" --data "$(base64 -i "${script_dir}/../go/bin/messenger")"
