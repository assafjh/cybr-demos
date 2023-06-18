#!/bin/bash

# This script will:
# 1. Authenticate to Conjur Cloud using the API Key
# 2. Retrieve a variable from Conjur Cloud

#======== Variables ===========
conjur_host=
# Host should be added to workload name, slashes should be url encoded - / = %2F 
# Example: branch/workload1 -> host%2Fbranch%2Fworkload1
host=
api_key=
# Slashes should be url encoded - / = %2F 
# Example: data/app/safe/secret1 -> data%2Fapp%2Fsafe%2Fsecret1
conjur_variable_path=
# If Conjur Cloud / Edge CA is not trusted, uncomment and modify the below
ca_cert_path="--cacert <path_to_certificate>"

#========= Script ===========

# Authenticating to Conjur
conjur_token=$(curl -s --request POST "$ca_cert_path" \
     --url "$conjur_host/api/authn/conjur/$host/authenticate" \
     --header 'Content-Type: application/json' \
     --header 'Accept-Encoding: base64' \
     --data "$api_key")

# Retriving variable from Conjur
conjur_variable_value=$(curl -s "$ca_cert_path" --request GET "$conjur_host/api/secrets/conjur/variable/$conjur_variable_path" \
         --header "Authorization: Token token=\"$conjur_token\"")

# Print the variable path and value
printf "=================\nVariable Path: %s\n\nVariable value: %s\n=================\n" "$conjur_variable_path" "$conjur_variable_value"