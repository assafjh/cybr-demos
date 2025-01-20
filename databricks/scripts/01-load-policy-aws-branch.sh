#!/bin/bash

# Script path
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Conjur CLI path
COP_CLI=/Applications/ConjurCloudCLI.app/Contents/Resources/conjur/conjur

# Replace with the assigned role name that will be used 
ROLE_NAME=ajh-ec2-pub-lab-role 

ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query "Role.Arn" --output text | awk -F':' '{print $5}' | sed 's/\/role\///g')/"$ROLE_NAME"
export ROLE_ARN

echo "$ROLE_ARN"

# Use envsubst to substitute the environment variables into the template
envsubst < "$SCRIPT_DIR"/../policies/02-define-aws-branch.yml > 02-define-aws-branch-filled.yml

# Apply the generated YAML
$COP_CLI policy update -b data -f 02-define-aws-branch-filled.yml

# Clean up the temporary YAML file
rm 02-define-aws-branch-filled.yml