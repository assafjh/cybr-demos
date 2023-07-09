#!/bin/sh
# Using Service Account JWT
JWT=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
# Authenticating to Conjur using above JWT
token=$(curl -k -s --request POST "$CONJUR_AUTHN_URL/$CONJUR_ACCOUNT/authenticate" --header 'Content-Type: application/x-www-form-urlencoded' --header "Accept-Encoding: base64" --data-urlencode "jwt=$JWT")
# Retrieving secret using short lived access token revcieved from Conjur
secret=$(curl -k -s -X GET -H "Authorization: Token token=\"$token\"" "$CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/$CONJUR_VARIABLE_PATH")
# Printing the secret   
echo "$CONJUR_VARIABLE_PATH value: $secret"
