# Azure DevOps Integration

This guide will demonstrate a pipeline authenticating via a Self-Hosted Linux Agent with a user/system assigned identity. 

Two ways to consume a secret will be demoed
- Rest API
- CyberArk Conjur Service Connector
	- Can be added to ADO via this link: [CyberArk Conjur Service Connector](https://marketplace.visualstudio.com/items?itemName=CyberArk.cyberark-conjur-credentials)

It is assumed you have access to an Azure Linux VM that can be used as an ADO Agent.

It is assumed that you need to assign a user identity to the VM - Instructions are provided and can be skipped in case you already have an identity assigned to your machine.

# Table of Contents
<!-- TOC -->

- [Azure DevOps Integration](#azure-devops-integration)
    - [Azure Authenticator](#azure-authenticator)
    - [How does the Azure Authenticator works?](#how-does-the-azure-authenticator-works)
    - [Create a managed identity](#create-a-managed-identity)
    - [Assign the managed identity to your VM](#assign-the-managed-identity-to-your-vm)
    - [Loading Conjur policies](#loading-conjur-policies)
        - [Conjur Enterprise](#conjur-enterprise)
            - [Root branch](#root-branch)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Update root policy](#update-root-policy)
                - [Logout from Conjur](#logout-from-conjur)
            - [Azure branch](#azure-branch)
                - [Login as user azure-manager01](#login-as-user-azure-manager01)
                - [Load azure policy](#load-azure-policy)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
            - [Azure Authenticator](#azure-authenticator)
                - [Login as user admin01](#login-as-user-admin01)
                - [Load the authenticator policy](#load-the-authenticator-policy)
                - [Enable the authenticator](#enable-the-authenticator)
            - [Populate secrets and Azure authenticator variables](#populate-secrets-and-azure-authenticator-variables)
            - [Logout from Conjur CLI](#logout-from-conjur-cli)
        - [Conjur Cloud](#conjur-cloud)
            - [Data branch](#data-branch)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Update data policy](#update-data-policy)
                - [Logout from Conjur](#logout-from-conjur)
            - [Azure branch](#azure-branch)
                - [Login as user azure-manager01](#login-as-user-azure-manager01)
                - [Load azure policy](#load-azure-policy)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
            - [Azure Authenticator](#azure-authenticator)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Load the authenticator policy](#load-the-authenticator-policy)
                - [Enable the authenticator](#enable-the-authenticator)
            - [Populate secrets and Azure authenticator variables](#populate-secrets-and-azure-authenticator-variables)
            - [Logout from Conjur CLI](#logout-from-conjur-cli)
    - [Create a demo project at Azure DevOps](#create-a-demo-project-at-azure-devops)
        - [Create a new project](#create-a-new-project)
        - [Create a new repository](#create-a-new-repository)
        - [Create a Personal Access Token PAT](#create-a-personal-access-token-pat)
        - [Create a self-hosted Linux agent](#create-a-self-hosted-linux-agent)
        - [Create a pipeline](#create-a-pipeline)

<!-- /TOC -->

## Azure Authenticator

The Conjur Azure Authenticator is a highly secure method for authenticating Azure workloads to Conjur using their underlying Microsoft Azure attributes. A Conjur identity can be established at varying granularity, allowing for a collection of resources to be identified to Conjur as one, or for individual workloads to be uniquely identified. 

The method is based on Microsoft Azure AD Authentication.

## How does the Azure Authenticator works?

![Conjur Azure authenticator](https://github.com/assafjh/cybr-demos/blob/main/azure-devops/azure-authenticator.png?raw=true)
**IMDS**: Instance Metadata Service

## 1. Create a managed identity
**Note**: In case you already have an identity assigned to your machine or you are going to use a System assigned identity, this step can be skipped
1. At *Azure Portal*, go to *Managed Identities*
2. Click *Create*
```properties
Subscription: your subscription
Resource group: your resource group
Region: your region
Name: conjur-managed-acct01
```
3. Click *Review + create*

## 2. Assign the managed identity to your VM
**Note**: Skip this step if step #1 was skipped
1. At *Azure Portal*, go to *Virtual machines*
2. Select your Linux VM
3. Select *Identity*
4. Select the tab *User assigned*
5. Click *Add*
```properties
Subscription: your subscription
User assigned managed identities: conjur-managed-acct01 # Select here the identity you have created at step #1
```
5. Click *Add*

## 3. Loading Conjur policies
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
#### Azure branch
##### 1. Login as user azure-manager01
- Use the API key as a password from the 01-base.log file for the user azure-admin01
```bash
conjur login -i azure-admin01
```
##### 2. Load azure policy
- Before running the export commands below, modify them with the correct values, if a *system assigned identity* is going to be used, comment line #42 and uncomment line #43 at the file *policies/conjur-enterprise/02-define-azure-branch.yml*
```bash
export SUBSCRIPTION_ID=<MY_AZURE_SUBSCRIPTION_ID>
export RESOURCE_GROUP=<MY_AZURE_RESOURCE_GROUP>
# export the line below only if user assigned identity is going to be used
export USER_ASSIGNED_IDENTITY_NAME=<USER_ASSIGNED_IDENTITY_NAME>
# export the line below only if system assigned identity is going to be used
export OBJECT_ID=<MY_AZURE_SYSTEM_ASSIGNED_IDENTITY_OBJECT_ID>
envsubst < conjur-enterprise/policies/02-define-azure-branch.yml > 02-define-azure-branch.yml
conjur policy update -b data/azure -f 02-define-azure-branch.yml | tee -a 02-define-azure-branch.log
```
##### 3. Logout from Conjur CLI
```Bash
conjur logout
```
#### Azure Authenticator
##### 1. Login as user admin01
 - Use the API key as a password from the 01-base.log file for the user admin01
```bash
conjur login -i admin01
```
##### 2. Load the authenticator policy
```Bash
conjur policy update -b root -f policies/conjur-enterprise/03-define-azure-auth.yml | tee -a 03-define-azure-auth.log
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
#### Populate secrets and Azure authenticator variables
1. Modify the variables at populate variables script:
```bash 
vi scripts/02-populate-variables.sh
```
```Bash
scripts/02-populate-variables.sh | tee -a 02-populate-variables.log
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
##### 2. Update data policy
```bash
conjur policy update -b data -f policies/conjur-cloud/01-base.yml | tee -a 01-base.log
```
##### 3. Logout from Conjur
```Bash
conjur logout
```
#### Azure branch
##### 1. Login as user azure-manager01
- Use the API key as a password from the 01-base.log file for the user azure-admin01
```bash
conjur login -i azure-admin01
```
##### 2. Load azure policy
- Before running the export commands below, modify them with the correct values, if a *system assigned identity* is going to be used, comment line #42 and uncomment line #43 at the file *policies/conjur-cloud/02-define-azure-branch.yml*
```bash
export SUBSCRIPTION_ID=<MY_AZURE_SUBSCRIPTION_ID>
export RESOURCE_GROUP=<MY_AZURE_RESOURCE_GROUP>
# export the line below only if user assigned identity is going to be used
export USER_ASSIGNED_IDENTITY_NAME=<USER_ASSIGNED_IDENTITY_NAME>
# export the line below only if system assigned identity is going to be used
export OBJECT_ID=<MY_AZURE_SYSTEM_ASSIGNED_IDENTITY_OBJECT_ID>
envsubst < policies/conjur-cloud/02-define-azure-branch.yml > 02-define-azure-branch.yml
conjur policy update -b data/azure -f 02-define-azure-branch.yml | tee -a 02-define-azure-branch.log
```
##### 3. Logout from Conjur CLI
```Bash
conjur logout
```
#### Azure Authenticator
##### 1. Login to Conjur as admin using the CLI
```bash
conjur login -i <username>
```
##### 2. Load the authenticator policy
```Bash
conjur policy update -b conjur/authn-azure -f policies/conjur-cloud/03-define-azure-auth.yml | tee -a 03-define-azure-auth.log
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
#### Populate secrets and Azure authenticator variables
1. Modify the variables at populate variables script:
```bash 
vi scripts/02-populate-variables.sh
```
```Bash
scripts/02-populate-variables.sh | tee -a 02-populate-variables.log
```
#### Logout from Conjur CLI
```Bash
conjur logout
```
## 4. Create a demo project at Azure DevOps
### 1. Create a new project
1. Connect to your ADO organization.
2. Click *New Project* and fill the form like the below
```properties
Project name: Conjur Demo
Visibility: Private
```
3. Click *Create*
### 2. Create a new repository
1. Select the Project *Conjur Demo*
2. Go to *Project settings -> Repos*
3. Click *Create* and fill the form like the below
```properties
Repository type: Git
Repository name: Conjur Demo
Add a README: true
```
4. Click *Create*
### 3. Create a Personal Access Token (PAT)
**Note**: The token will be used for Linux agent authentication described at step #4
1. Go to Azure DevOps *User Settings*
2. Select *Personal access tokens*
3. Click *New Token* and fill the form
```properties
# This is an example for the PAT details
Name: Conjur Demo
Orginization: MyOrgName
Expiration (UTC): 30 days
Scopes: Full Access
```
4. Click *Create*
5. **This token cannot be retrieved later. So make sure you copy it**

### 4. Create a self-hosted Linux agent
1. Select the Project *Conjur Demo*
2. Go to *Project settings -> Agent pools*
3. Click *Add Pool* and fill the form like the below
```properties
Pool to link: New
Pool type: Self-hosted
Name: Conjur Agent
Grant access permission to all pipelines: true
```
4. Click *Create*
5. Select the agent *Conjur Agent*
6. Click *New agent*
7. Select the tab *Linux* and follow the instructions
Example:
```bash
On the Linux machine, run the following:
# Download the agent
wget https://vstsagentpackage.azureedge.net/agent/2.217.2/vsts-agent-linux-x64-2.217.2.tar.gz
# Unpack the agent
mkdir myagent && cd myagent
tar zxvf ~/vsts-agent-linux-x64-2.217.2.tar.gz
# Configure the agent
./config.sh
<< EOF
Y #After reading the agreement
https://dev.azure.com/MyOrginizationName
PAT # Press Enter for PAT
$PAT_VALUE_FROM_STEP_3
EOF
```
If there is a need to configure the agent service on the Linux machine, use:
```bash
sudo ./svc.sh
```
### 5. Create a pipeline
1. At this repo, modify *pipeline/azure-pipelines.yml* variables block
```bash
vi azure-pipelines.yml
```
Example
```yaml
variables:
# Lines #9 - #24
# Conjur URL
- name: conjur_url
  value: https://conjur-leader.example.local:443
# Conjur Authenticator ID
- name: CONJUR_AUTHN_ID
  value: devops
# Conjur Tenant ID
- name: conjur_account
  value: conjur
# Conjur Identity (Default value is configured below)
- name: conjur_identity
  value: host%2Fdata%2Fazure%2Fapps%2Fmanaged-identity01
# Conjur variable path (Default value is configured below)
- name: conjur_variable_path
  value: data/azure/apps/safe/secret1
```
2. Go to the project *Conjur Demo*
3. Select *Pipelines*
4. Click on *New pipeline*
```properties
Where is your code?: Azure Repos Git
Select a repository: Conjur Demo
Configure your pipeline: Starter pipeline
Review your pipeline YAML: Paste the contents of the modified *pipeline/azure-pipelines.yml* to ADO file editor
```
5. Click *Save and run*
6. Check that the run was successful
