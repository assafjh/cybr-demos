# Use case: Amazon Lambda function IAM role authentication

It is assumed that you can create a new lambda function and that an IAM role is already associated with the lambda function.

For more information on lambda functions: [AWS Docs - lambda](https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html)

# Table of Contents
<!-- TOC -->

- [Use case: Amazon Lambda function IAM role authentication](#use-case-amazon-lambda-function-iam-role-authentication)
    - [Configure Lambda function](#configure-lambda-function)
        - [Create a new lambda function with runtime Python v3.10](#create-a-new-lambda-function-with-runtime-python-v310)
        - [Package the function](#package-the-function)
        - [Upload the zip file to you lambda function](#upload-the-zip-file-to-you-lambda-function)
        - [Configure the following Environment variables:](#configure-the-following-environment-variables)
    - [Loading Conjur policies](#loading-conjur-policies)
        - [Conjur Enterprise](#conjur-enterprise)
            - [Root branch](#root-branch)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Update root policy](#update-root-policy)
                - [Logout from Conjur](#logout-from-conjur)
            - [AWS branch](#aws-branch)
                - [Login as user aws-admin01](#login-as-user-aws-admin01)
                - [Load aws policy](#load-aws-policy)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
            - [IAM Authenticator](#iam-authenticator)
                - [Login as user admin01](#login-as-user-admin01)
                - [Load the authenticator policy](#load-the-authenticator-policy)
                - [Enable the authenticator](#enable-the-authenticator)
            - [Populate safe variables](#populate-safe-variables)
            - [Logout from Conjur CLI](#logout-from-conjur-cli)
        - [Conjur Cloud](#conjur-cloud)
            - [Data branch](#data-branch)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Update data policy](#update-data-policy)
                - [Logout from Conjur](#logout-from-conjur)
            - [AWS branch](#aws-branch)
                - [Login as user aws-admin01](#login-as-user-aws-admin01)
                - [Load aws policy](#load-aws-policy)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
            - [IAM Authenticator](#iam-authenticator)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Load the authenticator policy](#load-the-authenticator-policy)
                - [Enable the authenticator](#enable-the-authenticator)
            - [Populate safe variables](#populate-safe-variables)
            - [Logout from Conjur CLI](#logout-from-conjur-cli)
    - [Test your function](#test-your-function)
        - [From AWS console, go to the lambda function and click Test](#from-aws-console-go-to-the-lambda-function-and-click-test)
        - [Validate that the output is correct](#validate-that-the-output-is-correct)

<!-- /TOC -->

## 1. Configure Lambda function
### Create a new lambda function with runtime Python v3.10
**Note**: The packaging script supports the latest lambda python runtime env, currently it is v3.10
### Package the function
**Note**: You can skip this phase by downloading a pre-packaged function from: [Releases - packaged Lambda function](https://github.com/assafjh/cybr-demos/releases/tag/built-lambda-function-python-v3.10)
```bash
scripts/01-package-function.sh
```
### Upload the zip file to you lambda function
```bash
# File will be generated under:
function-source-code/conjur-lambda-package.zip
```
### Configure the following Environment variables:
```properties
AUTHN_IAM_SERVICE_ID=demo
CONJUR_ACCOUNT=conjur
# Conjur FQDN with scheme and port
CONJUR_APPLIANCE_URL=https://$CONJUR_FQDN:$PORT
# Conjur host ID
CONJUR_AUTHN_LOGIN=$CONJUR_HOST
# AWS IAM Role Name
IAM_ROLE_NAME=$ROLE_NAME
```

## 2. Loading Conjur policies
- Policy statements are loaded into either the Conjur root/data policy branch or a policy branch under root/data.
- Per best practices, most policies will be created in branches off of root/data.
- Branches have the following advantages: better organizing, help policy isolation for least privilege assignments, enforce RBAC, allowing relevant users to manage their own policy.
- The demo uses an organizational structure that can be found under the folder ***policies***.

### Conjur Enterprise
####  Root branch
##### 1. Login to Conjur as admin using the CLI
```bash
conjur login -i admin
```
##### 2. Update root policy
```bash
conjur policy update -b root -f policies/conjur-enterprise/01-base.yml | tee -a 01-base.log
```
##### 3. Logout from Conjur
```Bash
conjur logout
```
#### AWS branch
##### 1. Login as user aws-admin01
- Use the API key as a password from the 01-base.log file for the user aws-admin01
```bash
conjur login -i aws-admin01
```
##### 2. Load aws policy
- Before running the export commands below, modify them with the correct values.
```bash
# ROLE_ARN structure is: $ACCOUNT_NUMBER/$ROLE_NAME
# Example: arn:aws:iam::1234:role/service-role/ajh-elastic-conjur-role-123 -> export ROLE_ARN=1234/ajh-elastic-conjur-role-123
export ROLE_ARN=<ROLE_ARN>
envsubst < policies/conjur-enterprise/02-define-aws-branch.yml > 02-define-aws-branch.yml
conjur policy update -b data/aws -f 02-define-aws-branch.yml | tee -a 02-define-aws-branch.log
```
##### 3. Logout from Conjur CLI
```Bash
conjur logout
```
#### IAM Authenticator
##### 1. Login as user admin01
 - Use the API key as a password from the 01-base.log file for the user admin01
```bash
conjur login -i admin01
```
##### 2. Load the authenticator policy
```Bash
conjur policy update -b root -f policies/conjur-enterprise/03-define-iam-auth.yml | tee -a 03-define-iam-auth.log
```
##### 3. Enable the authenticator
- This step will work from the Conjur Leader VM only.
1. Modify the variables at enable authenticator script:
```bash 
vi scripts/02-enable-authenticator.sh
```
2. Run the script:
```bash
scripts/02-enable-authenticator.sh
```
#### Populate safe variables
1. Modify the variables at populate variables script:
```bash 
vi scripts/03-populate-variables.sh
```
```Bash
scripts/03-populate-variables.sh | tee -a 03-populate-variables.log
```
#### Logout from Conjur CLI
```Bash
conjur logout
```
### Conjur Cloud
####  Data branch
##### 1. Login to Conjur as admin using the CLI
```bash
conjur login -i <username>
```
##### 2. Update data policy
```bash
conjur policy update -b data -f policies/conjur-cloud/01-base.yml | tee -a 01-base.log
```
##### 3. Logout from Conjur
```Bash
conjur logout
```
#### AWS branch
##### 1. Login as user aws-admin01
- Use the API key as a password from the 01-base.log file for the user aws-admin01
```bash
conjur login -i aws-admin01
```
##### 2. Load aws policy
- Before running the export commands below, modify them with the correct values.
```bash
# ROLE_ARN structure is: $ACCOUNT_NUMBER/$ROLE_NAME
# Example: arn:aws:iam::1234:role/service-role/ajh-elastic-conjur-role-123 -> export ROLE_ARN=1234/ajh-elastic-conjur-role-123
export ROLE_ARN=<ROLE_ARN>
envsubst < policies/conjur-cloud/02-define-aws-branch.yml > 02-define-aws-branch.yml
conjur policy update -b data/aws -f 02-define-aws-branch.yml | tee -a 02-define-aws-branch.log
```
##### 3. Logout from Conjur CLI
```Bash
conjur logout
```
#### IAM Authenticator
##### 1. Login to Conjur as admin using the CLI
```bash
conjur login -i <username>
```
##### 2. Load the authenticator policy
```Bash
conjur policy update -b conjur/authn-iam -f policies/conjur-cloud/03-define-iam-auth.yml | tee -a 03-define-iam-auth.log
```
##### 3. Enable the authenticator
1. Modify the variables at enable authenticator script:
```bash 
vi scripts/02-enable-authenticator.sh
```
2. Run the script:
```bash
scripts/02-enable-authenticator.sh
```
#### Populate safe variables
1. Modify the variables at populate variables script:
```bash 
vi scripts/03-populate-variables.sh
```
```Bash
scripts/03-populate-variables.sh | tee -a 03-populate-variables.log
```
#### Logout from Conjur CLI
```Bash
conjur logout
```
## 4. Test your function
### From AWS console, go to the lambda function and click Test
###  Validate that the output is correct

