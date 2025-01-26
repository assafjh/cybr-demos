#!/bin/bash
#============ Variables ===============
# If needed, modify the below to configure Conjur CLI location
CONJUR_CLI=${CONJUR_CLI:-/Applications/ConjurCloudCLI.app/Contents/Resources/conjur/conjur}

# Issuer parameters
ISSUER=${ISSUER:-aws-demo-s3-issuer}
MAX_TTL=900
TYPE=aws

# AWS Region, Role/User, and S3 Bucket
AWS_REGION=${AWS_REGION:-eu-west-2}
AWS_POLICY_NAME=${AWS_POLICY_NAME:-ajh-dynamic-secrets-s3-policy}
AWS_ROLE_NAME=${AWS_ROLE_NAME:-ajh-dynamic-secrets-s3-role}
AWS_USER_NAME=${AWS_USER_NAME:-ajh-dynamic-secrets-s3-user}
AWS_S3_BUCKET=${AWS_S3_BUCKET:-ajh-conjur-demo}

#============ functions ===============

# ========================
# CONJUR LOGIN CHECK
# ========================
check_conjur_login() {
  if ! command -v "$CONJUR_CLI" whoami > /dev/null; then
    echo "[ERROR] Conjur CLI not found at $CONJUR_CLI. Please ensure it's installed and accessible."
    exit 1
  fi

  echo "[INFO] Checking Conjur login status..."
  if ! "$CONJUR_CLI" whoami > /dev/null 2>&1; then
    echo "[INFO] Not logged into Conjur. Prompting for login."
    read -p "Enter Conjur Username: " CONJUR_USERNAME
    read -s -p "Enter Conjur Password: " CONJUR_PASSWORD
    echo
    echo "$CONJUR_PASSWORD" | "$CONJUR_CLI" login -i "$CONJUR_USERNAME" -p-
    if [ $? -ne 0 ]; then
      echo "[ERROR] Failed to log into Conjur. Please check your credentials."
      exit 1
    fi
  else
    echo "[INFO] Already logged into Conjur."
  fi
}

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
    --arg bucket "arn:aws:s3:::$AWS_S3_BUCKET" \
    --arg bucket_objects "arn:aws:s3:::$AWS_S3_BUCKET/*" \
    '{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetObject",
            "s3:ListBucket"
          ],
          "Resource": [$bucket, $bucket_objects]
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
    ACCESS_KEY_ID=$(echo "$USER_KEYS" | jq -r '.AccessKeyId')
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

  $CONJUR_CLI issuer create \
      --id "$ISSUER" \
      --max-ttl "$MAX_TTL" \
      --type "$TYPE" \
      --data "{\"access_key_id\": \"$ACCESS_KEY_ID\", \"secret_access_key\": \"$SECRET_ACCESS_KEY\"}"

  if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to create Conjur Issuer"
    exit 1
  fi

  echo "[INFO] Conjur Issuer created successfully with ID: $ISSUER"
}

# ========================
# CONJUR POLICY SETUP
# ========================
setup_conjur_policy() {
  check_conjur_login
  
  echo "[INFO] Setting up Conjur Policy for AWS Dynamic Secrets"

  # Retrieve AWS Role ARN dynamically
  AWS_ROLE_ARN=$(aws iam get-role --role-name "$AWS_ROLE_NAME" --query 'Role.Arn' --output text)

  if [ -z "$AWS_ROLE_ARN" ]; then
    echo "[ERROR] Unable to retrieve ARN for role $AWS_ROLE_NAME. Ensure the role exists."
    exit 1
  fi

  echo "[INFO] Using AWS Role ARN: $AWS_ROLE_ARN"

  # Create a temporary file for the policy
  TEMP_POLICY_FILE=$(mktemp)
  
  cat <<EOF > "$TEMP_POLICY_FILE"
- !variable
  id: aws-demo-s3-dynamic-secret
  annotations:
    dynamic/issuer: $ISSUER
    dynamic/region: $AWS_REGION
    dynamic/method: assume-role
    dynamic/role-arn: $AWS_ROLE_ARN
EOF

  echo "[INFO] Loading Conjur policy from temporary file: $TEMP_POLICY_FILE"

  $CONJUR_CLI policy update -b data/dynamic -f "$TEMP_POLICY_FILE"

  if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to load Conjur policy"
    rm -f "$TEMP_POLICY_FILE" # Clean up the temporary file
    exit 1
  fi

  echo "[INFO] Conjur policy loaded successfully"
  rm -f "$TEMP_POLICY_FILE" # Clean up the temporary file

  # Create a temporary file for the policy
  TEMP_POLICY_FILE=$(mktemp)
  
  cat <<EOF > "$TEMP_POLICY_FILE"
- !permit
  role: !group aws/iam-roles
  privileges: [ read, execute ]
  resource: !variable dynamic/aws-demo-s3-dynamic-secret
EOF

  echo "[INFO] Loading Conjur policy from temporary file: $TEMP_POLICY_FILE"

  $CONJUR_CLI policy update -b data -f "$TEMP_POLICY_FILE"

  if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to load Conjur policy"
    rm -f "$TEMP_POLICY_FILE" # Clean up the temporary file
    exit 1
  fi

  echo "[INFO] Conjur policy loaded successfully"
  rm -f "$TEMP_POLICY_FILE" # Clean up the temporary file

}

# ========================
# MAIN SCRIPT
# ========================
case "$1" in
  create-aws-resources)
    setup_aws
    ;;
  delete-aws-resources)
    cleanup_aws
    ;;
  create-conjur-issuer)
    setup_conjur_issuer
    ;;
  create-conjur-policy)
    setup_conjur_policy
    ;;
  create-all-resources)
    setup_aws
    setup_conjur_issuer
    setup_conjur_policy
    ;;
  *)
    echo "Usage: $0 {create-all-resources|create-aws-resources|create-conjur-issuer|create-conjur-policy|delete-aws-resources}"
    exit 1
    ;;
esac
