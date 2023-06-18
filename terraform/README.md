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
conjur policy update -b root -f policies/01-base | tee -a 01-base.log
```
#### 3. Logout from Conjur
```Bash
conjur logout
```
### 2. Terraform branch
#### 1. Login as user terraform-manager01
- Use the API key as a password from the 01-base.log file for the user jenkins-manager01
```bash
conjur login -i terraform-manager01
```
#### 2. Load terraform policy
```bash
conjur policy update -b terraform -f policies/02-define-terraform-branch.yml | tee -a 02-define-terraform-branch.log
```
#### 3. Populate the secrets a variables
```Bash
scripts/03-populate-variables | tee -a 03-populate-variables.log
```
#### 4. Logout from Conjur CLI
```Bash
conjur logout
```
### 3. Run the Terraform Plans
#### 1. Plan: attributes
##### 1. Modify the provider attributes at the tf file 
```bash
vi plans/attributes/attributes.tf
```
- Example:
```properties
...
provider  "conjur" {
	# Conjur FQDN including scheme and port
	appliance_url =  "https://conjur:8443"
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
##### 2. Run the plan
The command that shall be used is ***plan*** and not ***apply*** since this is a demonstration.
```bash
scripts/04-run-attributes-plan.sh
```
#### Modify scripts/.env
The next use cases will use environment parameters in order to authenticate, both will use the same file.
```bash
vi scripts/.env
```
- Example:
```properties
...
# Conjur FQDN including scheme and port
export CONJUR_APPLIANCE_URL=https://conjur:8443
# Conjur Account
export CONJUR_ACCOUNT=conjur
# Path to Conjur public key file
export CONJUR_CERT_FILE="$HOME"/conjur-server.pem
...
```
#### Run envvars plan
- Before run, modify CONJUR_AUTHN_LOGIN and CONJUR_AUTHN_API_KEY in the script.
# Conjur identity api key
```bash
scripts/05-run-envvars-plan.sh
```
#### Run summon plan
- Before run, modify CONJUR_AUTHN_LOGIN and CONJUR_AUTHN_API_KEY in the script.
```bash
scripts/06-run-summon-plan.sh
```
