#!/bin/bash
# This script will enable the AWS IAM Authn in Conjur.
# For Conjur Enterprise - This script is meant to use at the Conjur Leader VM machine.
# For Conjur Cloud - This script Needs access to Conjur Cloud CLI.
#============ Variables =======================
# Name of the authn to enable, leave as is
AUTHN_TO_ENABLE=authn-iam/demo
# If needed, modify the below to configure Conjur CLI location
CONJUR_CLI=conjur

#============ Conjur Cloud ====================
# If Conjur Cloud, change to true
IS_CONJUR_CLOUD=false

#============ Conjur Enterprise ===============
# Is sudo required to run docker/podman - leave empty if no need
SUDO=
# Using docker/podman
CONTAINER_MGR=docker
# Conjur Leader port
CONJUR_LEADER_PORT=443
# Conjur Leader container ID
CONTAINER_ID=$(curl -s -k "https://127.0.0.1:$CONJUR_LEADER_PORT/info" | awk '/container/ {print $2}' | tr -d '",')

#============ Script ===============
if [[ "${IS_CONJUR_CLOUD}" == "true" ]]; then
    "$CONJUR_CLI" authenticator enable --id  "${AUTHN_TO_ENABLE}"
else
    echo "Enabling $AUTHN_TO_ENABLE authn for Conjur"
    CONJUR_AUTHENTICATORS=$($SUDO $CONTAINER_MGR exec $CONTAINER_ID evoke variable list | grep CONJUR_AUTHENTICATORS)
    CONJUR_AUTHENTICATORS=$(echo $CONJUR_AUTHENTICATORS | awk -F "=" '{print $2}')
    CONJUR_AUTHENTICATORS=$(sed -e 's/^"//' -e 's/"$//' <<< "$CONJUR_AUTHENTICATORS")
    IFS=','
    read -a array <<< "$CONJUR_AUTHENTICATORS"
    if [[ "${IFS}${array[*]}${IFS}" =~ "${IFS}$AUTHN_TO_ENABLE${IFS}" ]]; then
        echo "Already Enabled"
        unset IFS
    else
        unset IFS
        [ -z "$CONJUR_AUTHENTICATORS" ] && CONJUR_AUTHENTICATORS=authn
        $SUDO $CONTAINER_MGR exec -it $CONTAINER_ID evoke variable set CONJUR_AUTHENTICATORS $CONJUR_AUTHENTICATORS,$AUTHN_TO_ENABLE
    fi
fi