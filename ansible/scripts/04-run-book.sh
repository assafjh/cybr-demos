#!/bin/bash
#============ Variables ===============
# Conjur tenant
export CONJUR_ACCOUNT=demo
# Conjur FQDN with schem and port
export CONJUR_APPLIANCE_URL=
# Conjur host identity
export CONJUR_AUTHN_LOGIN=host/ansible/apps/conjur-demo
# Conjur host identity API key
export CONJUR_AUTHN_API_KEY=
# Conjur variable path
export CONJUR_VARIABLE_PATH=ansible/apps/safe/secret1
# Conjur public key file path, in case of Conjur cloud - comment line #14
export CONJUR_CERT_FILE="$HOME"/conjur-server.pem
#========== Script ===============
# Loading functions snippet
source ./functions
# Playbook lookup command will change according to Ansible version
decide_values_for_playbook
cd ../playbook || exit 1
# Playbook generating playbook from template
envsubst < "./playbook.template" > "playbook.yml"
# Running Playbook
ansible-playbook playbook.yml -vv