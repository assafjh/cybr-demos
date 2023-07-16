# CircleCI integration

The workflow authenticates to Conjur using JWT authentication.

## How does the JWT Authenticator works?
![Conjur JWT authenticator](https://github.com/assafjh/cybr-demos/blob/main/kubernetes-jwt/jwt-authenticator.png?raw=true)
For more details on CircleCI OIDC, please refer to:
[CircleCI: Using OpenID Connect Tokens in Jobs](https://circleci.com/docs/openid-connect-tokens/)

For an example CircleCI payload, take a look at the file: `claims-example.json`

## 1. Loading Conjur policies
- Policy statements are loaded into either the Conjur root/data policy branch or a policy branch under root/data.
- Per best practices, most policies will be created in branches off of root/data.
- Branches have the following advantages: better organizing, help policy isolation for least privilege assignments, enforce RBAC, allowing relevant users to manage their own policy.
- The demo uses an organizational structure that can be found under the folder ***policies***.
### Conjur Enterprise
#### Root branch
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
#### CircleCI branch
##### 1. Login as user circleci-admin01
- Use the API key as a password from the 01-base.log file for the user circleci-admin01
```bash
conjur login -i circleci-admin01
```
##### 2. Load circleci policy
- Before running the export commands below, modify them with the correct values.
```bash
export CIRCLECI_ORG_ID=<MY_ORG_ID>
export CIRCLECI_PROJECT_ID=<MY_PROJECT_ID>
# How to get User ID: GET https://circleci.com/api/v2/me
export CIRCLECI_USER_ID=<MY_USER_ID>
export CIRCLECI_CONTEXT_ID=<MY_CONTEXT_ID>
envsubst < policies/conjur-enterprise/02-define-circleci-branch.yml > 02-define-circleci-branch.yml
conjur policy update -b data/circleci -f 02-define-circleci-branch.yml | tee -a 02-define-circleci-branch.log
```
##### 3. Logout from Conjur CLI
```Bash
conjur logout
```
#### JWT Authenticator
##### 1. Login as user admin01
 - Use the API key as a password from the 01-base.log file for the user admin01
```bash
conjur login -i admin01
```
##### 2. Load the authenticator policy
```Bash
conjur policy update -b root -f policies/conjur-enterprise/03-define-jwt-auth.yml | tee -a 03-define-jwt-auth.log
```
##### 3. Enable the authenticator
- This step will work from the Conjur Leader VM only.
1. Modify the variables at enable authenticator script:
```bash 
vi scripts/01-enable-authenticator.sh
```
2. Run the script:
```bash
scripts/01-enable-authenticator.sh
```
##### 4. Populate secrets and JWT authenticator variables
1. Modify the variables at populate variables script:
```bash 
vi scripts/02-populate-variables.sh
```
```Bash
scripts/02-populate-variables.sh | tee -a 02-populate-variables.log
```
##### 5. Check that the authenticator is working properly
 1. Modify the variables at enable authenticator script:
```bash 
vi scripts/03-check-authenticator.sh
```
2. Run the script:
```bash
scripts/03-check-authenticator.sh
```
#### Logout from Conjur CLI
```Bash
conjur logout
```
### Conjur Cloud
#### Data branch
##### 1. Login to Conjur as admin using the CLI
```bash
conjur login -i <username>
```
##### 2. Update root policy
```bash
conjur policy update -b data -f policies/conjur-cloud/01-base.yml | tee -a 01-base.log
```
##### 3. Logout from Conjur
```Bash
conjur logout
```
#### CircleCI branch
##### 1. Login as user circleci-admin01
- Use the API key as a password from the 01-base.log file for the user circleci-admin01
```bash
conjur login -i circleci-admin01
```
##### 2. Load circleci policy
- Before running the export commands below, modify them with the correct values.
```bash
export CIRCLECI_ORG_ID=<MY_ORG_ID>
export CIRCLECI_PROJECT_ID=<MY_PROJECT_ID>
# How to get User ID: GET https://circleci.com/api/v2/me
export CIRCLECI_USER_ID=<MY_USER_ID>
export CIRCLECI_CONTEXT_ID=<MY_CONTEXT_ID>
envsubst < policies/conjur-cloud/02-define-circleci-branch.yml > 02-define-circleci-branch.yml
conjur policy update -b data/circleci -f 02-define-circleci-branch.yml | tee -a 02-define-circleci-branch.log
```
##### 3. Logout from Conjur CLI
```Bash
conjur logout
```
#### JWT Authenticator
##### 1. Login as user admin01
 - Use the API key as a password from the 01-base.log file for the user admin01
```bash
conjur login -i admin01
```
##### 2. Load the authenticator policy
```Bash
conjur policy update -b conjur/authn-jwt -f policies/conjur-cloud/03-define-jwt-auth.yml | tee -a 03-define-jwt-auth.log
```
##### 3. Enable the authenticator
1. Modify the variables at enable authenticator script:
```bash 
vi scripts/01-enable-authenticator.sh
```
2. Run the script:
```bash
scripts/01-enable-authenticator.sh
```
##### 4. Populate secrets and JWT authenticator variables
1. Modify the variables at populate variables script:
```bash 
vi scripts/02-populate-variables.sh
```
```Bash
scripts/02-populate-variables.sh | tee -a 02-populate-variables.log
```
##### 5. Check that the authenticator is working properly
 1. Modify the variables at enable authenticator script:
```bash 
vi scripts/03-check-authenticator.sh
```
2. Run the script:
```bash
scripts/03-check-authenticator.sh
```
#### Logout from Conjur CLI
```Bash
conjur logout
```
## 3. Connect CircleCI to GitHub

## 4. In GitHub, commit and push the file workflows/config.yml to .circleci/config.yml

## 5. Enable the Project at CircleCI
### In CircleCI Projects page, select your repository and click "Set Up Project"
### In the form that was opened, select "Fastest", Click Set Up Project

## 6. Add the context "Conjur" to your project.
#### In CircleCI, click on "*organization settings*" -> "*Contexts*" -> "*Create Context*"
#### Name the context "*Conjur*"
#### Add the following environment variables:
- `CONJUR_AUTHN_ID`- For this demo, the Conjur authenticator ID is: **circleci1**
- `CONJUR_FQDN` - Add Conjur FQDN with scheme and port
- `CONJUR_ORG` - or this demo, the Conjur organization ID is: **demo**

### 7. Run the workflow
#### Modify the file dummy-file and commit
#### In CircleCI look at your dashboard and make sure the workflow ran 
#### Examine the steps, see that the secret has been printed.
