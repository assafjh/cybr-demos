#!/bin/bash

# Script path
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Using kubectl/oc
COP_CLI=kubectl

# Fetch values from ConfigMap
export CONJUR_APPLIANCE_URL=$(kubectl get configmap conjur-connect -n conjur-jwt-cc -o jsonpath='{.data.CONJUR_APPLIANCE_URL}')
export CONJUR_ACCOUNT=$(kubectl get configmap conjur-connect -n conjur-jwt-cc -o jsonpath='{.data.CONJUR_ACCOUNT}')
export CONJUR_AUTHENTICATOR_ID=$(kubectl get configmap conjur-connect -n conjur-jwt-cc -o jsonpath='{.data.CONJUR_AUTHENTICATOR_ID}')

# Use envsubst to substitute the environment variables into the template
envsubst < $SCRIPT_DIR/../manifests/08-jwt-eso.yml > 08-jwt-eso.yml

# Apply the generated YAML
$COP_CLI apply -f 08-jwt-eso.yml

# Clean up the temporary YAML file
rm 08-jwt-eso.yml
