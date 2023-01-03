
# Ansible integration
This demo supports integration with Ansible version 2.8 and up.

- For Ansible version 2.8, the demo will use the plugin: [ansible-conjur-host-identity](https://github.com/cyberark/ansible-conjur-host-identity)
- For Ansible version 2.9 and above, the demo will use the plugin: [CyberArk Ansible Conjur Collection](https://galaxy.ansible.com/cyberark/conjur)

## 1. Install Ansible
If needed, install Ansible
```bash
scripts/01-install-ansible﻿.sh
```
## 2. Install Conjur plugin for Ansible
**Note**: The script will decide and install the appropriate plugin, according to your Ansible version.
```bash
scripts/02-install-plugin.sh.sh
```
## 3. Loading Conjur policies
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
### 2. Ansible branch
#### 1. Login as user ansible-manager01
- Use the API key as a password from the 01-base.log file for the user ansible-manager01
```bash
conjur login -i ansible-manager01
```
#### 2. Load ansible policy
```bash
conjur policy update -b ansible -f policies/02-define-ansible-branch.yml | tee -a 02-define-ansible-branch.log
```
#### 3. Populate Conjur variables
```Bash
scripts/03-populate-variables.sh | tee -a 03-populate-variables.sh
```
### 5. Logout from Conjur CLI
```Bash
conjur logout
```
## 3. Run the playbook
**Note**: The script will generate the playbook automatically, a template for the book can be found under the ``playbook`` folder.
**Note
### 1. Modify the script variables
```bash
vi scripts/04-run-book.sh
```
For example:
```properties
...
#============ Variables ===============
# Conjur tenant
export CONJUR_ACCOUNT=demo
# Conjur FQDN with schem and port
export CONJUR_APPLIANCE_URL=https://conjur:8443
# Conjur host identity
export CONJUR_AUTHN_LOGIN=host/ansible/apps/conjur-demo
# Conjur host identity API key
export CONJUR_AUTHN_API_KEY=1234
# Conjur variable path
export CONJUR_VARIABLE_PATH=ansible/apps/safe/secret1
# Conjur public key file path, in case of Conjur cloud - comment line #14
export CONJUR_CERT_FILE="$HOME"/conjur-server.pem
...
```
### 2. Run the playbook
```bash
scripts/04-run-book.sh
```
## Troubleshooting
### On Conjur Cloud, when running the playbook, getting an error from the certificate verification 
#### 1. Comment out from  run book script line 14:
```bash
vi scripts/04-run-book.sh
...
# export CONJUR_CERT_FILE="$HOME"/conjur-server.pem
...
```
#### 2. Unset CONJUR_CERT_FILE
```bash
unset CONJUR_CERT_FILE
```
#### 3. Update Python trust store
```bash
python3 -m pip install --upgrade certifi
```
### When running Ansible on a Mac, getting ERROR! A worker was found in a dead state
#### Error details
```
may have been in progress in another thread when fork() was called. We cannot safely call it or ignore it in the fork() child process. Crashing instead. Set a breakpoint on objc_initializeAfterForkError to debug.
```
#### Solution
This is apparently due to some new security changes made in High Sierra that are breaking lots of Python things that use fork()
```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```
