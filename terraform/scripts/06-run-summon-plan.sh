#!/bin/bash
# This script will run the Terraform plan summon.tf located under the plans/summon folder and prints the output as json file.
# Before running this, please make sure to edit .env with with the relevant conjur provider attributes.
#============ Variables ===============
source .env
# Conjur identity
export CONJUR_AUTHN_LOGIN=host/data/terraform/plans/summon/plan1
# Conjur identity api key
export CONJUR_AUTHN_API_KEY=$CONJUR_API_KEY
#============ Script ===============
cd ../plans/summon || exit 1
printf "===== Running speculative execution plan =====\n\n"
terraform init
summon -f ./config/secrets.yml terraform plan -out=summon-plan
printf "\n===== Result =====\n"
terraform show -json summon-plan
