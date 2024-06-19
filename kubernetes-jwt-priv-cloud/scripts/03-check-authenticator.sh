#!/bin/bash

# This script will:
# 1. Login to Conjur to get an API Key
# 2. Authenticate to Conjur using the API Key
# 3. Will query the status end point of the authenticators

#======== Variables ===========
# Conjur URL
conjur_url=https://assaf-lab.secretsmgr.cyberark.cloud/api
# Conjur account
conjur_account=conjur
# User with read permissions to the status endpoint
username=
# Password for the user mentioned above
password=
# Type of the authn
authn_type=authn-jwt
# Name of the authn
authn_id=k8s-cluster1

#======== Script ===========

# Login to Conjur, get an API Key
api_key=$(curl -k -s -X GET -u "$username:$password" "$conjur_url/authn/$conjur_account/login")

# Authenticate to conjur, get a temporary token
token=$(curl -s -k --header "Accept-Encoding: base64" --data "$api_key" "$conjur_url/authn/$conjur_account/$username/authenticate")

# Using the temporary token, retriving variable from Conjur
curl -k --header "Authorization: Token token=\"$token\"" "$conjur_url/$authn_type/$authn_id/$conjur_account/status"

