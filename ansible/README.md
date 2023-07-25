# Ansible integration
This demo supports integration with Ansible version 2.8 and up.

- For Ansible version 2.8, the demo will use the plugin: [ansible-conjur-host-identity](https://github.com/cyberark/ansible-conjur-host-identity)
- For Ansible version 2.9 and above, the demo will use the plugin: [CyberArk Ansible Conjur Collection](https://galaxy.ansible.com/cyberark/conjur)

# Table of Contents
<!-- TOC -->

- [Ansible integration](#ansible-integration)
    - [Install Ansible](#install-ansible)
    - [Install Conjur plugin for Ansible](#install-conjur-plugin-for-ansible)
    - [Loading Conjur policies](#loading-conjur-policies)
        - [Conjur Enterprise](#conjur-enterprise)
            - [Root branch](#root-branch)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Update root policy](#update-root-policy)
                - [Logout from Conjur](#logout-from-conjur)
            - [Ansible branch](#ansible-branch)
                - [Login as user ansible-admin01](#login-as-user-ansible-admin01)
                - [Load ansible policy](#load-ansible-policy)
                - [Populate Conjur variables](#populate-conjur-variables)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
        - [Conjur Cloud](#conjur-cloud)
            - [Data branch](#data-branch)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Update data policy](#update-data-policy)
                - [Logout from Conjur](#logout-from-conjur)
            - [Ansible branch](#ansible-branch)
                - [Login as user ansible-admin01](#login-as-user-ansible-admin01)
                - [Load ansible policy](#load-ansible-policy)
                - [Populate Conjur variables](#populate-conjur-variables)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
    - [Run the playbook](#run-the-playbook)
        - [Modify the script variables](#modify-the-script-variables)
        - [Run the playbook](#run-the-playbook)
    - [Troubleshooting](#troubleshooting)
        - [On Conjur Cloud, when running the playbook, getting an error from the certificate verification](#on-conjur-cloud-when-running-the-playbook-getting-an-error-from-the-certificate-verification)
            - [Comment out from  run book script line 14:](#comment-out-from--run-book-script-line-14)
            - [Unset CONJUR_CERT_FILE](#unset-conjur_cert_file)
            - [Update Python trust store](#update-python-trust-store)
        - [When running Ansible on a Mac, getting ERROR! A worker was found in a dead state](#when-running-ansible-on-a-mac-getting-error-a-worker-was-found-in-a-dead-state)
            - [Error details](#error-details)
            - [Solution](#solution)

<!-- /TOC -->

## Install Ansible
If needed, install Ansible
```bash
scripts/01-install-ansible.sh
```

## Install Conjur plugin for Ansible
**Note**: The script will decide and install the appropriate plugin, according to your Ansible version.
```bash
scripts/02-install-plugin.sh
```

## Loading Conjur policies
- Policy statements are loaded into either the Conjur root/data policy branch or a policy branch under root/data.
- Per best practices, most policies will be created in branches off of root/data.
- Branches have the following advantages: better organizing, help policy isolation for least privilege assignments, enforce RBAC, allowing relevant users to manage their own policy.
- The demo uses an organizational structure that can be found under the folder ***policies***.

### Conjur Enterprise

#### Root branch

##### Login to Conjur as admin using the CLI
```bash
conjur login -i admin
```

##### Update root policy
```bash
conjur policy update -b root -f policies/conjur-enterprise/01-base.yml | tee -a 01-base.log
```

##### Logout from Conjur
```Bash
conjur logout
```

#### Ansible branch

##### Login as user ansible-admin01
- Use the API key as a password from the 01-base.log file for the user ansible-admin01
```bash
conjur login -i ansible-admin01
```

##### Load ansible policy
```bash
conjur policy update -b data/ansible -f policies/conjur-enterprise/02-define-ansible-branch.yml | tee -a 02-define-ansible-branch.log
```

##### Populate Conjur variables
1. Modify the variables at populate variables script:
```bash
vi  scripts/03-populate-variables.sh
```
2. Run the script:
```Bash
scripts/03-populate-variables.sh | tee -a 03-populate-variables.sh
```

##### Logout from Conjur CLI
```Bash
conjur logout
```

### Conjur Cloud

#### Data branch

##### Login to Conjur as admin using the CLI
```bash
conjur login -i <username>
```

##### Update data policy
```bash
conjur policy update -b data -f policies/conjur-cloud/01-base.yml | tee -a 01-base.log
```

##### Logout from Conjur
```Bash
conjur logout
```

#### Ansible branch

##### Login as user ansible-admin01
- Use the API key as a password from the 01-base.log file for the user ansible-admin01
```bash
conjur login -i ansible-admin01
```

##### Load ansible policy
```bash
conjur policy update -b data/ansible -f policies/conjur-cloud/02-define-ansible-branch.yml | tee -a 02-define-ansible-branch.log
```

##### Populate Conjur variables
1. Modify the variables at populate variables script:
```bash
vi  scripts/03-populate-variables.sh
```
2. Run the script:
```Bash
scripts/03-populate-variables.sh | tee -a 03-populate-variables.sh
```

##### Logout from Conjur CLI
```Bash
conjur logout
```

## Run the playbook
**Note**: The script will generate the playbook automatically, a template for the book can be found under the ``playbook`` folder.
**Note

### Modify the script variables
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

### Run the playbook
```bash
scripts/04-run-book.sh
```

## Troubleshooting

### On Conjur Cloud, when running the playbook, getting an error from the certificate verification 

#### Comment out from  run book script line 14:
```bash
vi scripts/04-run-book.sh
...
# export CONJUR_CERT_FILE="$HOME"/conjur-server.pem
...
```

#### Unset CONJUR_CERT_FILE
```bash
unset CONJUR_CERT_FILE
```

#### Update Python trust store
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
