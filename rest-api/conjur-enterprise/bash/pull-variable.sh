#!/bin/bash

# This script will:
# 1. Login to Conjur to get an API Key
# 2. Authenticate to Conjur using the API Key
# 3. Retrieve a variable from Conjur

#======== Variables ===========
conjur_url=
conjur_account=conjur
username=
password=
# Slashes should be url encoded - / = %2F 
# Example: root/app/safe/secret1 -> root%2Fapp%2Fsafe%2Fsecret1
conjur_variable_path=

#======== Script ===========

# Login to Conjur, get an API Key
api_key=$(curl -k -s -X GET -u "$username:$password" "$conjur_url/authn/$conjur_account/login")

# Authenticate to conjur, get a temporary token
token=$(curl -s -k --header "Accept-Encoding: base64" --data "$api_key" "$conjur_url/authn/$conjur_account/$username/authenticate")

# Using the temporary token, retriving variable from Conjur
conjur_variable_value=$(curl -s -k --header "Authorization: Token token=\"$token\"" "$conjur_url/secrets/$conjur_account/variable/$conjur_variable_path")

# Print the variable path and value
printf "=================\nVariable Path: %s\n\nVariable value: %s\n=================\n" "$conjur_variable_path" "$conjur_variable_value"

