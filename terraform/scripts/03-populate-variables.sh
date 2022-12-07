#!/bin/bash
#============ Variables ===============
# Path to our safes at Conjur, leave as is
SAFE_PATH=terraform/plans/safe/
# Secret variable name, leave as is
VARIABLE_NAME=secret
# safe names, leave as is
declare -a SAFE_NAMES=("attributes" "envvars" "summon")

#============ Script ===============

# Checking if a user is logged-in to Conjur-CLI
conjur whoami

# Populate safe secrets with values
for i in "${SAFE_NAMES[@]}"
do
    for k in {1..3}
    do
        if command -p md5sum  /dev/null >/dev/null 2>&1
        then
            conjur variable set -i "$SAFE_PATH$i/$VARIABLE_NAME$k" -v "$(echo $RANDOM | md5sum | head -c 20; echo;)"
        else
            conjur variable set -i "$SAFE_PATH$i/$VARIABLE_NAME$k" -v "$(echo $RANDOM | md5 | head -c 20; echo;)"
        fi
    done
done

