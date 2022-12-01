#!/bin/bash
# This script will run the Terraform plan attribute.tf located under the plans/attributes folder and prints the output as json file.
# Before running this, please make sure to edit plans/attributes/attribute.tf with with the relevant conjur provider attributes.
#============ Script ===============
cd ../plans/attributes || exit 1
printf "===== Running speculative execution plan =====\n\n"
terraform init
terraform plan -out=attributes-plan
printf "\n===== Result =====\n"
terraform show -json attributes-plan 
