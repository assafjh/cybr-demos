#!/bin/bash
# This script will deploy Ansible AWX Operator and will deploy a demo instance
# Installation instructions: https://github.com/ansible/awx-operator
#================ Variables ==============
# Using kubectl/oc
COP_CLI=kubectl
#================ Script ==============
cd ../manifests || exit 1

# First we will apply the operator
$COP_CLI apply -k .
# Now we will apply again for the instance to be deployed
$COP_CLI apply -k .
