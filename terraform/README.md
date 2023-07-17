# Terraform integration

Terraform automates infrastructure build out, versioning, and change management. 

This demo uses Conjur Provider from Terrafrom registry and Summon in order to pull secrets from Conjur.

- All plans are stored under the ***plans*** folder.

- For more details on Conjur Provider, take a look at [Conjur Provider for Terraform](https://registry.terraform.io/providers/cyberark/conjur/latest/docs)

- For more details on Summon, take a look at [CyberArk Summon](https://cyberark.github.io/summon/)

#### Use cases:
1. Terraform plan that uses provider attributes to pull a secret from Conjur.
2. Terraform plan that uses provider envvars to pull a secret from Conjur.
3. Terraform plan that uses Summon to pull a secret from Conjur.

# Table of Contents
<!-- TOC -->

- [Terraform integration](#terraform-integration)
            - [Use cases:](#use-cases)
    - [Install Terraform](#install-terraform)
    - [Install Summon](#install-summon)
    - [Loading Conjur policies](#loading-conjur-policies)
        - [Conjur Enterprise](#conjur-enterprise)
            - [Root branch](#root-branch)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Update root policy](#update-root-policy)
                - [Logout from Conjur](#logout-from-conjur)
            - [Terraform branch](#terraform-branch)
                - [Login as user terraform-admin01](#login-as-user-terraform-admin01)
            - [Load terraform policy](#load-terraform-policy)
            - [Populate secret variables](#populate-secret-variables)
            - [Logout from Conjur CLI](#logout-from-conjur-cli)
        - [Conjur Cloud](#conjur-cloud)
            - [Root branch](#root-branch)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Update data policy](#update-data-policy)
                - [Logout from Conjur](#logout-from-conjur)
            - [Terraform branch](#terraform-branch)
                - [Login as user terraform-admin01](#login-as-user-terraform-admin01)
            - [Load terraform policy](#load-terraform-policy)
            - [Populate secret variables](#populate-secret-variables)
            - [Logout from Conjur CLI](#logout-from-conjur-cli)
    - [Run Terraform Plans](#run-terraform-plans)
        - [Plan: attributes](#plan-attributes)
            - [Modify the provider attributes at the tf file](#modify-the-provider-attributes-at-the-tf-file)
            - [Run plan](#run-plan)
        - [Modify scripts/.env](#modify-scriptsenv)
        - [Run envvars plan](#run-envvars-plan)
        - [Run summon plan](#run-summon-plan)

<!-- /TOC -->

## 1. Install Terraform
If needed, you can run the below script to install Terraform
```bash
scripts/01-install-terraform.sh
```

## 2. Install Summon
If needed, you can run the below script to install Summon
```bash
scripts/02-install-summon.sh
```

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
#### Terraform branch
##### 1. Login as user terraform-admin01
- Use the API key as a password from the 01-base.log file for the user terraform-admin01
```bash
conjur login -i terraform-admin01
```
#### 2. Load terraform policy
```bash
conjur policy update -b data/terraform -f policies/conjur-enterprise/02-define-terraform-branch.yml | tee -a 02-define-terraform-branch.log
```
#### 3. Populate secret variables
```Bash
scripts/03-populate-variables | tee -a 03-populate-variables.log
```
#### 4. Logout from Conjur CLI
```Bash
conjur logout
```
### Conjur Cloud
#### Root branch
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
#### Terraform branch
##### 1. Login as user terraform-admin01
- Use the API key as a password from the 01-base.log file for the user terraform-admin01
```bash
conjur login -i terraform-admin01
```
#### 2. Load terraform policy
```bash
conjur policy update -b data/terraform -f policies/conjur-cloud/02-define-terraform-branch.yml | tee -a 02-define-terraform-branch.log
```
#### 3. Populate secret variables
```Bash
scripts/03-populate-variables | tee -a 03-populate-variables.log
```
#### 4. Logout from Conjur CLI
```Bash
conjur logout
```
## 4. Run Terraform Plans
### Plan: attributes
#### 1. Modify the provider attributes at the tf file 
```bash
vi plans/attributes/attributes.tf
```
- Example:
```properties
...
provider  "conjur" {
	# Conjur FQDN including scheme and port
	appliance_url =  "https://conjur:443"
	# Path to Conjur public key file
	ssl_cert_path =  "/home/user/conjur-server.pem"
	# Conjur Account
	account =  "conjur"
	# Conjur identity
	login =  "host/identity"
	# Conjur identity api key
	api_key =  "123456"
}
...
```
#### 2. Run plan
The command that shall be used is ***plan*** and not ***apply*** since this is a demonstration.
```bash
scripts/04-run-attributes-plan.sh
```
### Modify scripts/.env
The next use cases will use environment parameters in order to authenticate, both will use the same file.
```bash
vi scripts/.env
```
- Example:
```properties
...
# Conjur FQDN including scheme and port
export CONJUR_APPLIANCE_URL=https://conjur:443
# Conjur Account
export CONJUR_ACCOUNT=conjur
# Conjur identity
export CONJUR_AUTHN_LOGIN=host/identity
# Conjur identity api key
export CONJUR_AUTHN_API_KEY=123456
# Path to Conjur public key file
export CONJUR_CERT_FILE="$HOME"/conjur-server.pem
...
```
### Run envvars plan
```bash
scripts/05-run-envvars-plan.sh
```
### Run summon plan
```bash
scripts/06-run-summon-plan.sh
```
