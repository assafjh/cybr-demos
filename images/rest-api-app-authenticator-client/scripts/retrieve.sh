#!/bin/sh
# Prepping the token
token="$(cat < /run/conjur/access-token | base64 -w 0)"
# Retrieving secret using short lived access token revcieved from Conjur
secret=$(curl -k -s -X GET -H "Authorization: Token token=\"$token\"" "$CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/data/kubernetes/applications/safe/secret1")
# Printing the secret
echo "SECRET1 value: $secret"