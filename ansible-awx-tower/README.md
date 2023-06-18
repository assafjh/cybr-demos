# Ansible AWX/Tower Integration

Integration steps are the same for Ansible AWX and Ansible Tower.

If needed, instructions are supplied for deploying an AWX instance on your Kubernetes node

**Two playbooks will be used**
- A playbook that reads a machine type credential
- A playbook that consumes multiple secrets from a custom type credential

## 1. Deploy AWX Instance
- If needed, install Ansible AWX
- Installation based on instructions from: [AWX Operator GitHub](https://github.com/ansible/awx-operator) and modified based on version 1.1.3
- All work will be done under the ***manifests*** folder
### 1. Modify kustomization.yml
#### 1. If needed, use a custom certificate
**Note**: You will need to provide a private and public key and save it to the manifests folder.
Uncomment lines #9 - #13
```yaml
...
# Uncomment for using a custom certificate
- name: awx-secret-tls
  type: kubernetes.io/tls
  files:
    - tls.crt # name of the public key file
    - tls.key # name of the private key file
...
```
#### 2. If needed, bypass Postgres configuration
Uncomment and modify lines #16 - #25
```yaml
...
# Uncomment for bypassing Postgres configuration
- name: awx-postgres-configuration
  type: Opaque
  literals:
  - host=awx-postgres-13
  - port=5432 # database port
  - database=awx # database name
  - username=awx # database username
  - password=Ansible123! # database username password
  - type=managed
  - sslmode=prefer
...
```
#### 3. Select AWX admin password
Modify line #31
```yaml
...
      - password=Ansible123!
...
```
#### 3. Select Operator namespace
Modify line #46
```yaml
...
namespace: awx
...
```
### 2. Modify pv.yml
#### 1. If there is a need for a persistent Postgres volume
**Note**: you will need to create a directory for the volume mount on your node.
Uncomment and modify lines #3 - #15
```yaml
...
# Uncomment if there is a need for a persistent postgres volume
apiVersion: v1
kind: PersistentVolume
metadata:
  name: awx-postgres-13-volume
spec:
  accessModes:
    - ReadWriteOnce
   persistentVolumeReclaimPolicy: Retain
   capacity:
   storage: 8Gi
   storageClassName: awx-postgres-volume
   hostPath:
     path: /awx-data/postgres-13 # Path to your directory on the node
...
```
#### 2. Modify the folder path for persistent projects volume
##### 1. Create the projects folder on the node
```bash
AWX_PROJECTS_PARENT_PATH=$HOME # Modify to desired path
mkdir -p "$AWX_PROJECTS_PARENT_PATH"/awx-data/projects
```
##### 2. Modify line  #31 to point to the folder created above
```yaml
    path: /home/ec2-user/awx-data/projects
```
### 3. Modify awx.yml
#### 1.  If using a custom certificate
Uncomment line #11
```yaml
...
  ingress_tls_secret: awx-secret-tls
...
```
#### 2.  Fill in external hostname or machine FQDN at line #14
```yaml
  hostname: awx-machine #That will be the address we will access AWX UI - https://awx-machine
```
#### 2.  If using custom Postgres configuration
Uncomment line #23
```yaml
...
  postgres_configuration_secret: awx-postgres-configuration
...
```
#### 3. If using a persistent volume for Postgres
Uncomment lines #26 - #29
```yaml
...
  postgres_storage_class: awx-postgres-volume
  postgres_storage_requirements:
   requests:
     storage: 8Gi
...
```
#### 4. If custom operator resource requirements are needed
Uncomment and modify lines #35 - #39
```yaml
...
  postgres_init_container_resource_requirements: {}
  postgres_resource_requirements: {}
  web_resource_requirements: {}
  task_resource_requirements: {}
  ee_resource_requirements: {}
...
```
#### 5. To open Ansible censored logs
Uncomment line #42
```
...
  no_log: false
...
```
### 4. Deploy AWX operator and instance
```bash
scripts/01-deploy-axw-operator-and-instance.sh
```

## 2. Loading Conjur policies
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
scripts/02-populate-variables.sh | tee -a 02-populate-variables.sh
```
### 5. Logout from Conjur CLI
```Bash
conjur logout
```

## 3. Configure AWX custom credential type: Conjur Secrets
Work will be done at AWX/Tower UI under Administration -> Credential Types
### 1. Click Add 
### 2. Fill the form
```properties
Name: Conjur Secrets
```
### 3. Copy the YAML below to the Input configuration form:
```yaml
---
fields:
  - id: variable_1
    type: string
    label: Variable 1 Path
    secret: true
  - id: variable_2
    type: string
    label: Variable 2 Path
    secret: true
  - id: variable_3
    type: string
    label: Variable 3 Path
    secret: true
required:
  - variable_1
  - variable_2
  - variable_3
```
### 4. Copy the YAML below to the Injector configuration form:
```yaml
---
extra_vars:
  variable_1: '{{ variable_1 }}'
  variable_2: '{{ variable_2 }}'
  variable_3: '{{ variable_3 }}'
```
### 5. Click Save

## 4. Configure a new AWX/Tower Organization
Work will be done at AWX/Tower UI under Access -> Organizations
### 1. Click Add 
### 2. Fill the form
```properties
Name: Conjur Demo
```
### 3. Click Save 

## 5. Configure AWX/Tower Credentials
Work will be done at AWX/Tower UI under Resources -> Credentials
### 1. Configure CyberArk Conjur Secrets Manager Lookup credential
#### 1. Click Add 
#### 2. Fill the form
```properties
Name: Conjur Instance
Orginization: Conjur Demo
Credential Type: CyberArk Conjur Secrets Manager Lookup
```
#### 3. Fill the type details form
```properties
Conjur URL: https://conjur-host:8433 #Conjur FQDN with scheme and port
API Key: 123456 #Use the API key as a password from the 02-define-ansible-branch.log file for the identity: host/ansible/apps/conjur-demo
Credential Type: CyberArk Conjur Secrets Manager Lookup
Account: conjur
Username: host/ansible/apps/conjur-demo
Public Key Certificate: # Copy the contents of your Conjur public key
```
#### 4. Click Test
##### 1. Fill in ``Secret Identifier``: ansible/apps/safe/secret1
##### 2. Click Run
Make Sure that Test passed
##### 3. Click Cancel
#### 5. Click Save

### 2. Configure Conjur Secrets credential
#### 1. Click Add 
#### 2. Fill the form
```properties
Name: Conjur Variables
Orginization: Conjur Demo
Credential Type: Conjur Secrets
```
#### 3. Fill the type details form
##### 1. Variable 1 Path
1. Click on the key icon next to the Variable1 Path input box.
2. Select **Conjur Instance**
3. Fill in ``Secret Identifier``: ansible/apps/safe/secret1
4. Click Test
Make Sure that Test passed
5. Click OK
##### 2. Variable 2 Path
1. Click on the key icon next to the Variable2 Path input box.
2. Select **Conjur Instance**
3. Fill in ``Secret Identifier``: ansible/apps/safe/secret1
4. Click Test
Make Sure that Test passed
5. Click OK
##### 3. Variable 3 Path
1. Click on the key icon next to the Variable3 Path input box.
2. Select **Conjur Instance**
3. Fill in ``Secret Identifier``: ansible/apps/safe/secret2
4. Click Test
Make Sure that Test passed
5. Click OK
#### 4. Click Save

### 3. Configure Machine credential
#### 1. Click Add 
#### 2. Fill the form
```properties
Name: Conjur Machine Secret
Orginization: Conjur Demo
Credential Type: Machine
```
#### 3. Fill the type details form
##### 1. Username
1. Fill in ``dummy``
##### 2. Password
1. Click on the key icon next to the Password input box.
2. Select **Conjur Instance**
3. Fill in ``Secret Identifier``: ansible/apps/safe/secret1
4. Click Test
Make Sure that Test passed
5. Click OK
##### 3. Click Save

## 6. Create Project
Work will be done at AWX/Tower UI under Resources -> Projects
#### 1. Click Add
#### 2. Fill the form
```properties
Name: Conjur Demo Project
Orginization: Conjur Demo
Source Control Type: Git
```
#### 3. Fill the type details form
```properties
Source Control URL: https://github.com/assafjh/cybr-demos.git
Source Control Branch/Tag/Commit: ansible-awx-tower-playbooks
```
#### 4. Click Save

### 3. Create an Inventory
Work will be done at AWX/Tower UI under Resources -> Inventories
#### 1. Click Add -> Add inventory template
#### 2. Fill the form
```properties
Name: Conjur
Orginization: Conjur Demo
```
#### 3. Click Save

## 7. Create a Template for using the Custom Secret type Playbook
Work will be done at AWX/Tower UI under Resources -> Templates
### 1. Click Add -> Add job template
### 2. Fill the form
```properties
Name: Conjur with Custom Type Credential
Job Type: Run
Inventory: Conjur
Project: Conjur Demo Project
Playbook: print-variables.yml
```
#### 3. Select credentials
##### 1. Under ```Credentials``` input box, select the ```magnifier glass``` icon
##### 2.  Selected Category is ```Conjur Secrets```
##### 3. Select ```Conjur Variables```
##### 4. Click ```Select```
### 4. Click Save
### 5. Click Launch
### 6. Take a look at the Job Output - see the variables printed
Example
```json
...
TASK [display variable 1] ******************************************************
ok: [localhost] => {
"variable_1": "60d689ca20ee0521ae30"
}
TASK [display variable 2] ******************************************************
ok: [localhost] => {
"variable_2": "9876be3dd08fde733894"
}
TASK [display variable 3] ******************************************************
ok: [localhost] => {
"variable_3": "7001eb20153a1faa8e2e"
}
...
```

## 8. Create a Template for using the Machine type Playbook
Work will be done at AWX/Tower UI under Resources -> Templates
### 1. Click Add -> Add job template
### 2. Fill the form
```properties
Name: Conjur with Machine Type Credential
Job Type: Run
Inventory: Conjur
Project: Conjur Demo Project
Playbook: print-machine-password.yml
```
### 3. Select credentials
##### 1. Under ```Credentials``` input box, select the ```magnifier glass``` icon
##### 2.  Selected Category is ```Machine```
##### 3. Select ```Conjur Machine Secret```
##### 4. Click ```Select```
### 4. Click Save
### 5. Click Launch
### 6. Take a look at the Job Output - see the variables printed
Example
```json
...
TASK [display encrypted password] **********************************************
ok: [localhost] => {
"ansible_password": "60d689ca20ee0521ae30"
}
...
```