# Jenkins integration
This demo uses a custom Jenkins image that's packaged and configured by using ***Configuration as Code*** plugin.

The Custom Jenkins Image is stored under a public repository: docker.io/assafhazan/jenkins.

For more details on the configuration and the image, take a look at the the folder ***jenkins-image***.

This demo can also use any other Jenkins instance, take note that additional steps will need to be taken, such as, installing the Conjur plugin.

## 1. Deploy Jenkins
If needed, deploy the custom Jenkins instance:
1. Modify the variables at the deployment script:
```bash 
vi scripts/01_deploy_jenkins.sh
```
2. Run the script:
```bash
scripts/01_deploy_jenkins.sh
```
## 2. Import Conjur public key to Jenkins' trust store
1. Modify the variables at the import certificate script:
```bash 
vi scripts/02_import_conjur_pub_key_into_jenkins_truststore.sh
```
2. Run the script:
```bash
scripts/02_import_conjur_pub_key_into_jenkins_truststore.sh
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
conjur policy update -b root -f policies/01_base.yml | tee -a 01_base.log
```
#### 3. Logout from Conjur
```Bash
conjur logout
```
### 2. Jenkins branch
#### 1. Login as user jenkins-manager01
- Use the API key as a password from the 01-base.log file for the user jenkins-manager01
```bash
conjur login -i jenkins-manager01
```
#### 2. Load jenkins policy
```bash
conjur policy update -b jenkins -f policies/02-define-jenkins-branch.yml | tee -a 02-define-jenkins-branch.log
```
#### 3. Logout from Conjur CLI
```Bash
conjur logout
```
### 3. JWT Authenticator
#### 1. Login as user admin01
 - Use the API key as a password from the 01-base.log file for the user admin01
```bash
conjur login -i admin01
```
#### 2. Load the authenticator policy
```Bash
conjur policy update -b root -f policies/03-define-jwt-auth.yml | tee -a 03-define-jwt-auth.log
```
#### 4. Enable the authenticator
- This step will work from the Conjur Leader VM only.
1. Modify the variables at enable authenticator script:
```bash 
vi scripts/03_enable_authenticator.sh
```
2. Run the script:
```bash
scripts/03_enable_authenticator.sh
```
#### 5. Populate the secrets and JWT authenticator variables
```Bash
scripts/04_populate_variables.sh | tee -a 04_populate_variables.log
```
### 6. Logout from Conjur CLI
```Bash
conjur logout
```
### 3. Jenkins projects
- We will deploy 3 folders and in each 1 project (2 pipelines, 1 freestyle).
- Build the projects according to the folder structure of ***jenkins-projects***.
- The naming convention is: ***[project-type]-[project-name]*** .
- Follow the instructions at each text file.