# Ansible integration
This demo supports integration with Ansible version 2.8 and up.

- For Ansible version 2.8, the demo will use the plugin: [ansible-conjur-host-identity](https://github.com/cyberark/ansible-conjur-host-identity)
- For Ansible version 2.9 and above, the demo will use the plugin: [CyberArk Ansible Conjur Collection](https://galaxy.ansible.com/cyberark/conjur)
  
# Table of Contents
- [Ansible integration](#ansible-integration)
- [Table of Contents](#table-of-contents)
  - [1. Install Ansible](#1-install-ansible)
  - [2. Install Conjur plugin for Ansible](#2-install-conjur-plugin-for-ansible)
  - [3. Loading Conjur policies](#3-loading-conjur-policies)
    - [Conjur Enterprise](#conjur-enterprise)
      - [Root branch](#root-branch)
        - [1. Login to Conjur as admin using the CLI](#1-login-to-conjur-as-admin-using-the-cli)
        - [2. Update root policy](#2-update-root-policy)
        - [3. Logout from Conjur](#3-logout-from-conjur)
      - [Ansible branch](#ansible-branch)
        - [1. Login as user ansible-admin01](#1-login-as-user-ansible-admin01)
        - [2. Load ansible policy](#2-load-ansible-policy)
        - [3. Populate Conjur variables](#3-populate-conjur-variables)
        - [4. Logout from Conjur CLI](#4-logout-from-conjur-cli)
    - [Conjur Cloud](#conjur-cloud)
      - [Data branch](#data-branch)
        - [1. Login to Conjur as admin using the CLI](#1-login-to-conjur-as-admin-using-the-cli-1)
        - [2. Update data policy](#2-update-data-policy)
        - [3. Logout from Conjur](#3-logout-from-conjur-1)
      - [Ansible branch](#ansible-branch-1)
        - [1. Login as user ansible-admin01](#1-login-as-user-ansible-admin01-1)
        - [2. Load ansible policy](#2-load-ansible-policy-1)
        - [3. Populate Conjur variables](#3-populate-conjur-variables-1)
        - [4. Logout from Conjur CLI](#4-logout-from-conjur-cli-1)
  - [3. Run the playbook](#3-run-the-playbook)
    - [1. Modify the script variables](#1-modify-the-script-variables)
    - [2. Run the playbook](#2-run-the-playbook)
  - [Troubleshooting](#troubleshooting)
    - [On Conjur Cloud, when running the playbook, getting an error from the certificate verification](#on-conjur-cloud-when-running-the-playbook-getting-an-error-from-the-certificate-verification)
      - [1. Comment out from  run book script line 14:](#1-comment-out-from--run-book-script-line-14)
      - [2. Unset CONJUR\_CERT\_FILE](#2-unset-conjur_cert_file)
      - [3. Update Python trust store](#3-update-python-trust-store)
    - [When running Ansible on a Mac, getting ERROR! A worker was found in a dead state](#when-running-ansible-on-a-mac-getting-error-a-worker-was-found-in-a-dead-state)
      - [Error details](#error-details)
      - [Solution](#solution)

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
#### Ansible branch
##### 1. Login as user ansible-admin01
- Use the API key as a password from the 01-base.log file for the user ansible-admin01
```bash
conjur login -i ansible-admin01
```
##### 2. Load ansible policy
```bash
conjur policy update -b data/ansible -f policies/conjur-enterprise/02-define-ansible-branch.yml | tee -a 02-define-ansible-branch.log
```
##### 3. Populate Conjur variables
```Bash
scripts/03-populate-variables.sh | tee -a 03-populate-variables.sh
```
##### 4. Logout from Conjur CLI
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
#### Ansible branch
##### 1. Login as user ansible-admin01
- Use the API key as a password from the 01-base.log file for the user ansible-admin01
```bash
conjur login -i ansible-admin01
```
##### 2. Load ansible policy
```bash
conjur policy update -b data/ansible -f policies/conjur-cloud/02-define-ansible-branch.yml | tee -a 02-define-ansible-branch.log
```
##### 3. Populate Conjur variables
```Bash
scripts/03-populate-variables.sh | tee -a 03-populate-variables.sh
```
##### 4. Logout from Conjur CLI
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
export CONJUR_ACCOUNT=conjur
# Conjur FQDN with scheme and port
export CONJUR_APPLIANCE_URL=https://conjur:443
# Conjur host identity
export CONJUR_AUTHN_LOGIN=data/host/ansible/apps/conjur-demo
# Conjur host identity API key
export CONJUR_AUTHN_API_KEY=1234
# Conjur variable path
export CONJUR_VARIABLE_PATH=data/ansible/apps/safe/secret1
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
