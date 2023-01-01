# Use case: Amazon Elastic Compute Cloud (EC2) IAM role authentication

It is assumed an IAM role is already associated with the ec2 instance. 

## 1. Loading Conjur policies
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
vi scripts/01-enable-authenticator.sh
```
2. Run the script:
```bash
scripts/01-enable-authenticator.sh
```
#### 5. Populate safe variables
1. Modify the variables at populate variables script:
```bash 
vi scripts/02-populate-variables.sh
```
```Bash
scripts/02-populate-variables.sh | tee -a 02-populate-variables.log
```
### 5. Logout from Conjur CLI
```Bash
conjur logout
```

## 4. Run the use case
### 1. Build the python environment
```bash
scripts/03-build-python-env.sh
```
### 3 Modify .env with relevant environment details
```bash
vi python/.env
```
### 3 Load .env
```bash
source python/.env
```
### 4. Run python shell script: ec2
```bash
python/ec2.py
```
### 5. Validate that the output is correct


