#!/bin/bash
#==========
SUDO=
CONTAINER_MGR=podman
CONJUR_LEADER_PORT=443
CONTAINER_ID=$(curl -s -k "https://127.0.0.1:$CONJUR_LEADER_PORT/info" | awk '/container/ {print $2}' | tr -d '",')
AUTHN_TO_ENABLE=authn-jwt/jenkins1
#==========
echo "Enabling $AUTHN_TO_ENABLE authn for Conjur"
CONJUR_AUTHENTICATORS=$($SUDO $CONTAINER_MGR exec $CONTAINER_ID evoke variable list | grep CONJUR_AUTHENTICATORS)
CONJUR_AUTHENTICATORS=$(echo $CONJUR_AUTHENTICATORS | awk -F "=" '{print $2}')
IFS=','
read -a array <<< "$CONJUR_AUTHENTICATORS"
if [[ "${IFS}${array[*]}${IFS}" =~ "${IFS}$AUTHN_TO_ENABLE${IFS}" ]]; then
    echo "Already Enabled"
    unset IFS
else
    unset IFS
    $SUDO $CONTAINER_MGR exec -it $CONTAINER_ID evoke variable set CONJUR_AUTHENTICATORS $CONJUR_AUTHENTICATORS,$AUTHN_TO_ENABLE
fi