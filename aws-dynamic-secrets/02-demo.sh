#!/bin/bash
set -euo pipefail

#============ Variables ===============
CONJUR_CLI="${CONJUR_CLI:-conjur}"   # override: export CONJUR_CLI=/path/to/conjur

# Issuer parameters
ISSUER=aws-demo-issuer

# AWS Region and Role — must match names used in 01-create-issuer.sh
AWS_REGION=eu-west-2
AWS_ROLE_NAME="dynamic-demo-secrets-ec2-role"

#============ functions ===============

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
  id: aws-demo-dynamic-secret
  annotations:
    dynamic/issuer: $ISSUER
    dynamic/region: $AWS_REGION
    dynamic/method: assume-role
    dynamic/role-arn: $AWS_ROLE_ARN
EOF

  echo "[INFO] Loading Conjur policy from temporary file: $TEMP_POLICY_FILE"

  "$CONJUR_CLI" policy update -b data/dynamic -f "$TEMP_POLICY_FILE"

  echo "[INFO] Conjur policy loaded successfully"
  rm -f "$TEMP_POLICY_FILE"
}

# ========================
# DEMO: RETRIEVE AWS DYNAMIC SECRET
# ========================
demo_dynamic_secret() {
  echo "[INFO] Retrieving AWS dynamic secret"

  AWS_CREDS=$("$CONJUR_CLI" variable get -i data/dynamic/aws-demo-dynamic-secret)

  echo "[INFO] AWS dynamic secret retrieved: $AWS_CREDS"

  AWS_ACCESS_KEY_ID=$(echo "$AWS_CREDS" | jq -r '.data.access_key_id')
  AWS_SECRET_ACCESS_KEY=$(echo "$AWS_CREDS" | jq -r '.data.secret_access_key')
  AWS_SESSION_TOKEN=$(echo "$AWS_CREDS" | jq -r '.data.session_token')

  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_SESSION_TOKEN

  echo "[INFO] Exported AWS credentials to environment variables"
}

# ========================
# DEMO: ACCESS AWS EC2 INSTANCE
# ========================
demo_ec2_access() {
  echo "[INFO] Verifying access to AWS EC2 instances"
  AWS_PAGER="" aws sts get-caller-identity --query "{Account: Account, Arn: Arn, UserId: UserId}" --output table
  AWS_PAGER="" aws ec2 describe-instances --query 'Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,PublicIP:PublicIpAddress,State:State.Name}' --output table --region "$AWS_REGION"
  echo "[INFO] Successfully accessed AWS EC2 instances"
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
# MAIN SCRIPT
# ========================
case "$1" in
  setup-conjur-policy)
    setup_conjur_policy
    ;;
  demo-dynamic-secret)
    check_conjur_login
    demo_dynamic_secret
    ;;
  demo-ec2-access)
    check_conjur_login
    demo_dynamic_secret
    demo_ec2_access
    ;;
  *)
    echo "Usage: $0 {setup-conjur-policy|demo-dynamic-secret|demo-ec2-access}"
    exit 1
    ;;
esac
