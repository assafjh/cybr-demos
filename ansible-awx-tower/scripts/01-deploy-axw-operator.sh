#!/bin/bash
# This script will deploy Ansible AWX Operator and will deploy a demo instance
# Installation instructions: https://github.com/ansible/awx-operator

#============ Variables ============
# Select in which parent folder to create the awx-data folder
# Do not forget to edit ../manifests/pv.yml line #31 with the path you have selected
AWX_PROJECTS_PARENT_PATH=$HOME

#============ Script ============
mkdir -p "$AWX_PROJECTS_PARENT_PATH"/awx-data/projects

cd ../manifests || exit 1

kubectl apply -k .
