#!/bin/bash
set -euo pipefail

#============ Variables ===============
CONJUR_CLI="${CONJUR_CLI:-conjur}"   # override: export CONJUR_CLI=/path/to/conjur

# Issuer parameters
ISSUER=aws-demo-issuer
MAX_TTL=900
TYPE=aws

# AWS resource names — customize to avoid collisions in shared accounts
AWS_POLICY_NAME="dynamic-demo-secrets-ec2-policy"
AWS_ROLE_NAME="dynamic-demo-secrets-ec2-role"
AWS_USER_NAME="dynamic-demo-secrets-ec2-user"

#============ functions ===============

# ========================
# AWS SETUP
# ========================
setup_aws() {
  echo "[INFO] Setting up AWS IAM Role, User, and Policy"

  # Create IAM User
  echo "[INFO] Creating IAM User"
  aws iam create-user --user-name "$AWS_USER_NAME" > /dev/null 2>&1 || echo "[INFO] User already exists."

  # Create the AWS IAM Policy JSON inline
  AWS_POLICY=$(jq -n \
    '{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "ec2:DescribeInstances",
            "ec2:StartInstances",
            "ec2:StopInstances"
          ],
          "Resource": "*"
        }
      ]
    }'
  )

  # Create IAM Policy
  POLICY_ARN=$(aws iam create-policy \
    --policy-name "$AWS_POLICY_NAME" \
    --policy-document "$AWS_POLICY" \
    --query 'Policy.Arn' \
    --output text)

  if [ -z "$POLICY_ARN" ]; then
    echo "[ERROR] Failed to create IAM policy"
    exit 1
  fi
  echo "[INFO] Created IAM Policy with ARN: $POLICY_ARN"

  # Attach Policy to User
  aws iam attach-user-policy \
    --user-name "$AWS_USER_NAME" \
    --policy-arn "$POLICY_ARN"

  echo "[INFO] Attached policy to IAM User"

  # Create IAM Role with Trust Policy referencing the specific user
  USER_ARN="arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):user/$AWS_USER_NAME"
  TRUST_POLICY=$(jq -n \
    --arg user_arn "$USER_ARN" \
    '{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "AWS": $user_arn
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }'
  )

  ROLE_ARN=$(aws iam create-role \
    --role-name "$AWS_ROLE_NAME" \
    --assume-role-policy-document "$TRUST_POLICY" \
    --query 'Role.Arn' \
    --output text)

  if [ -z "$ROLE_ARN" ]; then
    echo "[ERROR] Failed to create IAM role"
    exit 1
  fi
  echo "[INFO] Created IAM Role with ARN: $ROLE_ARN"

  # Attach Policy to Role
  aws iam attach-role-policy \
    --role-name "$AWS_ROLE_NAME" \
    --policy-arn "$POLICY_ARN"

  echo "[INFO] Attached policy to IAM Role"

  # Create Access Keys for User
  echo "[INFO] Creating Access Keys for IAM User"
  USER_KEYS=$(aws iam create-access-key \
    --user-name "$AWS_USER_NAME" \
    --query '{AccessKeyId: AccessKey.AccessKeyId, SecretAccessKey: AccessKey.SecretAccessKey}' \
    --output json 2>/dev/null)

  if [ -z "$USER_KEYS" ]; then
    echo "[ERROR] Failed to create access keys. User might already have 2 keys."
    exit 1
  fi

  ACCESS_KEY_ID=$(echo "$USER_KEYS" | jq -r '.AccessKeyId')
  SECRET_ACCESS_KEY=$(echo "$USER_KEYS" | jq -r '.SecretAccessKey')

  echo "[INFO] Created Access Keys for IAM User"
}

# ========================
# AWS CLEANUP
# ========================
cleanup_aws() {
  echo "[INFO] Cleaning up AWS resources"

  # Get the ARN of the policy
  echo "[INFO] Retrieving policy ARN for $AWS_POLICY_NAME"
  POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$AWS_POLICY_NAME'].Arn" --output text)

  if [ -z "$POLICY_ARN" ]; then
    echo "[ERROR] Policy ARN for $AWS_POLICY_NAME not found. Skipping policy detachment and deletion."
  else
    # Detach policy from the role
    echo "[INFO] Detaching policy from the IAM Role"
    aws iam detach-role-policy \
      --role-name "$AWS_ROLE_NAME" \
      --policy-arn "$POLICY_ARN"

    # Detach policy from the user
    echo "[INFO] Detaching policy from the IAM User"
    aws iam detach-user-policy \
      --user-name "$AWS_USER_NAME" \
      --policy-arn "$POLICY_ARN"

    # Delete IAM Policy
    echo "[INFO] Deleting IAM Policy: $AWS_POLICY_NAME"
    aws iam delete-policy --policy-arn "$POLICY_ARN"
  fi

  # Delete Access Keys for the User
  echo "[INFO] Deleting access keys for IAM User"
  ACCESS_KEY_IDS=$(aws iam list-access-keys --user-name "$AWS_USER_NAME" --query 'AccessKeyMetadata[*].AccessKeyId' --output text)
  for KEY_ID in $ACCESS_KEY_IDS; do
    aws iam delete-access-key --user-name "$AWS_USER_NAME" --access-key-id "$KEY_ID"
    echo "[INFO] Deleted access key $KEY_ID"
  done

  # Delete IAM Role
  echo "[INFO] Deleting IAM Role: $AWS_ROLE_NAME"
  aws iam delete-role --role-name "$AWS_ROLE_NAME" || echo "[ERROR] Failed to delete IAM Role. Ensure all policies are detached."

  # Delete IAM User
  echo "[INFO] Deleting IAM User: $AWS_USER_NAME"
  aws iam delete-user --user-name "$AWS_USER_NAME" || echo "[ERROR] Failed to delete IAM User. Ensure all access keys are deleted."

  echo "[INFO] AWS Cleanup Completed"
}


# ========================
# CONJUR LOGIN CHECK
# ========================
check_conjur_login() {
  echo "[INFO] Checking Conjur login status"
  if ! "$CONJUR_CLI" whoami > /dev/null 2>&1; then
    echo "[INFO] Not logged into Conjur. Prompting for login."
    read -rp "Enter Conjur Username: " CONJUR_USERNAME
    read -s -rp "Enter Conjur Password: " CONJUR_PASSWORD
    echo
    if ! echo "$CONJUR_PASSWORD" | "$CONJUR_CLI" login -i "$CONJUR_USERNAME" -p- > /dev/null 2>&1; then
      echo "[ERROR] Failed to log into Conjur. Please check your credentials."
      exit 1
    fi
  else
    echo "[INFO] Already logged into Conjur."
  fi
}

# ========================
# CONJUR ISSUER SETUP
# ========================
setup_conjur_issuer() {
  check_conjur_login
  echo "[INFO] Setting up Conjur Issuer"

  if [ -z "$ACCESS_KEY_ID" ] || [ -z "$SECRET_ACCESS_KEY" ]; then
    echo "[INFO] Checking for existing AWS access keys"
    USER_KEYS=$(aws iam list-access-keys \
      --user-name "$AWS_USER_NAME" \
      --query 'AccessKeyMetadata[0].AccessKeyId' \
      --output text)

    if [ -n "$USER_KEYS" ]; then
    ACCESS_KEY_ID="$USER_KEYS"
    echo "[INFO] Found existing access key: $ACCESS_KEY_ID"
    
    echo "[WARNING] SecretAccessKey cannot be retrieved for an existing access key."
    echo "[WARNING] If you need a SecretAccessKey, the existing key must be deleted and recreated."
    
    read -rp "Do you want to delete the existing key and create a new one? (y/n): " RECREATE_KEY
    if [ "$RECREATE_KEY" == "y" ]; then
        aws iam delete-access-key --user-name "$AWS_USER_NAME" --access-key-id "$ACCESS_KEY_ID"
        echo "[INFO] Deleted existing access key: $ACCESS_KEY_ID"
        
        NEW_KEYS=$(aws iam create-access-key \
        --user-name "$AWS_USER_NAME" \
        --query '{AccessKeyId: AccessKey.AccessKeyId, SecretAccessKey: AccessKey.SecretAccessKey}' \
        --output json)

        ACCESS_KEY_ID=$(echo "$NEW_KEYS" | jq -r '.AccessKeyId')
        SECRET_ACCESS_KEY=$(echo "$NEW_KEYS" | jq -r '.SecretAccessKey')
        echo "[INFO] Created new access keys: $ACCESS_KEY_ID"
    else
        SECRET_ACCESS_KEY="[Cannot retrieve existing SecretAccessKey. Please recreate if needed.]"
        echo "[INFO] Retaining existing access key."
    fi
    else
    echo "[INFO] No existing access keys found. Creating a new one."
    NEW_KEYS=$(aws iam create-access-key \
        --user-name "$AWS_USER_NAME" \
        --query '{AccessKeyId: AccessKey.AccessKeyId, SecretAccessKey: AccessKey.SecretAccessKey}' \
        --output json)

    ACCESS_KEY_ID=$(echo "$NEW_KEYS" | jq -r '.AccessKeyId')
    SECRET_ACCESS_KEY=$(echo "$NEW_KEYS" | jq -r '.SecretAccessKey')
    echo "[INFO] Created new access keys for IAM User."
    fi

  fi

  "$CONJUR_CLI" issuer create \
      --id "$ISSUER" \
      --max-ttl "$MAX_TTL" \
      --type "$TYPE" \
      --data "{\"access_key_id\": \"$ACCESS_KEY_ID\", \"secret_access_key\": \"$SECRET_ACCESS_KEY\"}"

  echo "[INFO] Conjur Issuer Created with ID: $ISSUER"
}

# ========================
# MAIN SCRIPT
# ========================
case "$1" in
  create-aws-resources)
    setup_aws
    ;;
  create-conjur-issuer)
    setup_conjur_issuer
    ;;
  delete-aws-resources)
    cleanup_aws
    ;;
  create-all-resources)
    setup_aws
    setup_conjur_issuer
    ;;
  *)
    echo "Usage: $0 {create-all-resources|create-aws-resources|create-conjur-issuer|delete-aws-resources}"
    exit 1
    ;;
esac
