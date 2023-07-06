#!/bin/bash

# This script will:
# 1. Authenticate to Conjur using the API Key
# 2. Retrieve a variable from Conjur Cloud

#======== Variables ===========
# Script path
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) 

conjur_url=https://aws-pub-lab
conjur_account=conjur
username=kubernetes-admin01
password=3bqzw8b167qpyqf9ab72rah52res62nb1p8q8gf3e83n0838v3521
# Slashes should be url encoded - / = %2F 
# Example: root/app/safe/secret1 -> root%2Fapp%2Fsafe%2Fsecret1
conjur_variable_path=data%2Fkubernetes%2Fapplications%2Fsafe%2Fmessenger

#======== Script ===========

# Login to Conjur, get an API Key
api_key=$(curl -k -s -X GET -u "$username:$password" "$conjur_url/authn/$conjur_account/login")

# Authenticate to conjur, get a temporary token
token=$(curl -s -k --header "Accept-Encoding: base64" --data "$api_key" "$conjur_url/authn/$conjur_account/$username/authenticate")

# Using the temporary token, setting a variable in Conjur
curl -k --header "Authorization: Token token=\"$token\"" "$conjur_url/secrets/$conjur_account/variable/$conjur_variable_path" --data $(base64 -i "${SCRIPT_DIR}/../go/bin/messenger")
