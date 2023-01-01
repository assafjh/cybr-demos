# Use case: Amazon Elastic Compute Cloud (EC2) IAM role authentication

It is assumed that you can create a new lambda function and that an IAM role is already associated with the lambda function.

For more information on lambda functions: [AWS Docs - lambda](https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html)

## 1. Configure Lambda function
### 1. Create a new lambda function with runtime Python v3.9
**Note**: The packaging script supports the latest lambda python runtime env, currently it is v3.9
### 2. Package the function
```bash
scripts/01-package-function.sh
```
### 2. Upload the zip file to you lambda function
```bash
# File will be generated under:
function-source-code/conjur-lambda-package.zip
```
### Configure the following Environment variables:
```properties
AUTHN_IAM_SERVICE_ID=demo
CONJUR_ACCOUNT=demo
# Conjur FQDN with scheme and port
CONJUR_APPLIANCE_URL=https://$CONJUR_FQDN:$PORT
# Conjur host ID
CONJUR_AUTHN_LOGIN=$CONJOR_HOST
# AWS IAM Role Name
IAM_ROLE_NAME=$ROLE_NAME
```

## 2. Loading Conjur policies
- Policy statements are loaded into either the Conjur root policy branch or a policy branch under root
- Per best practices, most policies will be created in branches off of root. 
- Branches have the following advantages: better organizing, help policy isolation for least privilege assignments, enforce RBAC, allowing relevant users to manage their own policy.
- The demo uses an organizational structure that can be found under the folder ***policies***.
### 1. Root branch
#### 1. Login to Conjur as admin using the CLI
```bash
conjur login -i admin
```
#### 2. Load root policy
```bash
conjur policy update -b root -f policies/01-base.yml | tee -a 01-base.log
```
#### 3. Logout from Conjur
```Bash
conjur logout
```
### 2. AWS branch
#### 1. Login as user aws-manager01
- Use the API key as a password from the 01-base.log file for the user circleci-manager01
```bash
conjur login -i aws-manager01
```
#### 2. Load aws policy
- Before running the export commands below, modify them with the correct values.
```bash
# ROLE_ARN structure is: $ACCOUNT_NUMBER/$ROLE_NAME
# Example: arn:aws:iam::1234:role/service-role/ajh-elastic-conjur-role-123 -> export ROLE_ARN=1234/ajh-elastic-conjur-role-123
export ROLE_ARN=<ROLE_ARN>
envsubst < policies/02-define-aws-branch.yml > 02-define-aws-branch.yml
conjur policy update -b aws -f 02-define-aws-branch.yml | tee -a 02-define-aws-branch.log
```
#### 3. Logout from Conjur CLI
```Bash
conjur logout
```
### 3. IAM Authenticator
#### 1. Login as user admin01
 - Use the API key as a password from the 01-base.log file for the user admin01
```bash
conjur login -i admin01
```
#### 2. Load the authenticator policy
```Bash
conjur policy update -b root -f policies/03-define-iam-auth.yml | tee -a 03-define-iam-auth.log
```
#### 3. Enable the authenticator
- This step will work from the Conjur Leader VM only.
1. Modify the variables at enable authenticator script:
```bash 
vi scripts/02-enable-authenticator.sh
```
2. Run the script:
```bash
scripts/02-enable-authenticator.sh
```
#### 5. Populate safe variables
1. Modify the variables at populate variables script:
```bash 
vi scripts/03-populate-variables.sh
```
```Bash
scripts/03-populate-variables.sh | tee -a 03-populate-variables.log
```
### 5. Logout from Conjur CLI
```Bash
conjur logout
```

## 4. Test your function
### 1. From AWS console, go to the lambda function and click Test
### 2. Validate that the output is correct


