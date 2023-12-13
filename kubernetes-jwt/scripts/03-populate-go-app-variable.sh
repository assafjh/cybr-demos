#!/bin/bash

# This script will:
# If Conjur Enterprise
#   1. Authenticate to Conjur using the API Key
#   2. Set a variable at Conjur Enterprise
# If Conjur Cloud:
#   1. Use conjur cli to update variable

# If you need check the b64 value of the binary:
#"$(base64 -i "${script_dir}/../go/bin/messenger")"

#======== Variables ===========
# Script path
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Conjur Cloud variables
is_conjur_cloud=false

# If needed, modify the below to configure Conjur CLI location
conjur_cli=conjur

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
    "$conjur_cli" variable set -i data/kubernetes/applications/safe/messenger -v "$(cat "${script_dir}"/../go/bin/messenger.b64)"
else
    # Login to Conjur, get an API Key
    api_key=$(curl -k -s -X GET -u "$username:$password" "$conjur_url/authn/$conjur_account/login")
    # Authenticate to conjur, get a temporary token
    token=$(curl -s -k --header "Accept-Encoding: base64" --data "$api_key" "$conjur_url/authn/$conjur_account/$username/authenticate")
    # Using the temporary token, setting a variable in Conjur
    curl -k --header "Authorization: Token token=\"$token\"" "$conjur_url/secrets/$conjur_account/variable/$conjur_variable_path" --data "$(cat "${script_dir}"/../go/bin/messenger.b64)"
fi
