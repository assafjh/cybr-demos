#!/bin/bash
#========== Script ===============
curl -s -k -o './info.json' https://127.0.0.1/info
echo "# auto-generated file" > conjur_env.properties
echo CONTAINER_ID=$(jq -r .container < ./info.json) >> conjur_env.properties
echo export ACCOUNT=$(jq -r .configuration.conjur.account < ./info.json) >> conjur_env.properties
echo export HOSTNAME=$(jq -r .configuration.conjur.hostname < ./info.json) >> conjur_env.properties
rm -f ./info.json
