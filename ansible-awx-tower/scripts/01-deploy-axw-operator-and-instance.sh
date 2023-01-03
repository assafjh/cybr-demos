#!/bin/bash
# This script will deploy Ansible AWX Operator and will deploy a demo instance
# Installation instructions: https://github.com/ansible/awx-operator

#============ Script ============
cd ../manifests || exit 1

# First we will apply the operator
kubectl apply -k .
# Now we will apply again for the instance to be deployed
kubectl apply -k .
