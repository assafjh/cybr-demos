# Azure DevOps Integration

The Conjur Azure Authenticator is a highly secure method for authenticating Azure workloads to Conjur using their underlying Microsoft Azure attributes. A Conjur identity can be established at varying granularity, allowing for a collection of resources to be identified to Conjur as one, or for individual workloads to be uniquely identified. 

The method is based on Microsoft Azure AD Authentication.

## How does the Azure Authenticator works?

![Conjur Azure authenticator](https://github.com/assafjh/cybr-demos/blob/main/azure-devops/azure-authenticator.png?raw=true)
## 1. Loading Conjur policies
- Policy statements are loaded into either the Conjur  root policy branch or a policy branch under root
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
### 2. Azure branch
#### 1. Login as user azure-manager01
- Use the API key as a password from the 01-base.log file for the user azure-manager01
```bash
conjur login -i azure-manager01
```
#### 2. Load azure policy
- Before running the export commands below, modify them with the correct values, if a *system assigned identity* is going to be used, comment line #42 and uncomment line #43 at the file *policies/02-define-azure-branch.yml*
```bash
export SUBSCRIPTION_ID=<MY_AZURE_SUBSCRIPTION_ID>
export RESOURCE_GROUP=<MY_AZURE_RESOURCE_GROUP>
# export the line below only if user assigned identity is going to be used
export USER_ASSIGNED_IDENTITY_NAME=<USER_ASSIGNED_IDENTITY_NAME>
# export the line below only if system assigned identity is going to be used
export OBJECT_ID=<MY_AZURE_SYSTEM_ASSIGNED_IDENTITY_OBJECT_ID>
envsubst < policies/02-define-azure-branch.yml > 02-define-azure-branch.yml
conjur policy update -b azure -f 02-define-azure-branch.yml | tee -a 02-define-azure-branch.log
```
#### 3. Logout from Conjur CLI
```Bash
conjur logout
```
### 3. Azure Authenticator
#### 1. Login as user admin01
 - Use the API key as a password from the 01-base.log file for the user admin01
```bash
conjur login -i admin01
```
#### 2. Load the authenticator policy
```Bash
conjur policy update -b root -f policies/03-define-azure-auth.yml | tee -a 03-define-azure-auth.log
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
#### 5. Populate the secrets and Azure authenticator variables
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
