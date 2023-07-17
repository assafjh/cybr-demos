# Jenkins integration
This demo uses a custom Jenkins image that's packaged and configured by using ***Configuration as Code*** plugin.

The Custom Jenkins Image is stored under a public repository: docker.io/assafhazan/jenkins.

For more details on the configuration and the image, take a look at the the folder ***jenkins-image***.

This demo can also use any other Jenkins instance, take note that additional steps will need to be taken, such as, installing the Conjur plugin.

# Table of Contents
<!-- TOC -->

- [Jenkins integration](#jenkins-integration)
    - [Deploy Jenkins](#deploy-jenkins)
    - [Import Conjur public key to Jenkins' trust store](#import-conjur-public-key-to-jenkins-trust-store)
    - [Loading Conjur policies](#loading-conjur-policies)
        - [Conjur Enterprise](#conjur-enterprise)
            - [Root branch](#root-branch)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Load root policy](#load-root-policy)
                - [Logout from Conjur](#logout-from-conjur)
            - [Jenkins branch](#jenkins-branch)
                - [Login as user jenkins-admin01](#login-as-user-jenkins-admin01)
                - [Load jenkins policy](#load-jenkins-policy)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
            - [JWT Authenticator](#jwt-authenticator)
                - [Login as user admin01](#login-as-user-admin01)
                - [Load the authenticator policy](#load-the-authenticator-policy)
                - [Enable the authenticator](#enable-the-authenticator)
                - [Populate secrets and JWT authenticator variables](#populate-secrets-and-jwt-authenticator-variables)
                - [Check that the authenticator is working properly](#check-that-the-authenticator-is-working-properly)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
        - [Conjur Cloud](#conjur-cloud)
            - [Root branch](#root-branch)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Update data policy](#update-data-policy)
                - [Logout from Conjur](#logout-from-conjur)
            - [Jenkins branch](#jenkins-branch)
                - [Login as user jenkins-admin01](#login-as-user-jenkins-admin01)
                - [Load jenkins policy](#load-jenkins-policy)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
            - [JWT Authenticator](#jwt-authenticator)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Load the authenticator policy](#load-the-authenticator-policy)
                - [Enable the authenticator](#enable-the-authenticator)
                - [Populate secrets and JWT authenticator variables](#populate-secrets-and-jwt-authenticator-variables)
                - [Check that the authenticator is working properly](#check-that-the-authenticator-is-working-properly)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
        - [Jenkins projects](#jenkins-projects)

<!-- /TOC -->

## 1. Deploy Jenkins
If needed, deploy the custom Jenkins instance:
1. Modify the variables at the deployment script:
```bash 
vi scripts/01-deploy-jenkins.sh
```
2. Run the script:
```bash
scripts/01-deploy-jenkins.sh
```
## 2. Import Conjur public key to Jenkins' trust store
Can skip if not using self-signed certificate
1. Modify the variables at the import certificate script:
```bash 
vi scripts/02-import-conjur-pub-key-into-jenkins-truststore.sh
```
2. Run the script:
```bash
scripts/02-import-conjur-pub-key-into-jenkins-truststore.sh
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
##### 2. Load root policy
```bash
conjur policy update -b root -f policies/conjur-enterprise/01-base.yml | tee -a 01-base.log
```
##### 3. Logout from Conjur
```Bash
conjur logout
```
#### Jenkins branch
##### 1. Login as user jenkins-admin01
- Use the API key as a password from the 01-base.log file for the user jenkins-admin01
```bash
conjur login -i jenkins-admin01
```
##### 2. Load jenkins policy
```bash
conjur policy update -b data/jenkins -f policies/conjur-enterprise/02-define-jenkins-branch.yml | tee -a 02-define-jenkins-branch.log
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
##### 3.Enable the authenticator
- This step will work from the Conjur Leader VM only.
1. Modify the variables at enable authenticator script:
```bash 
vi scripts/03-enable-authenticator.sh
```
2. Run the script:
```bash
scripts/03-enable-authenticator.sh
```
##### 4. Populate secrets and JWT authenticator variables
1. Modify the variables at populate variables script:
```bash
vi  scripts/04-populate-variables.sh
```
2. Run the script:
```Bash
scripts/04-populate-variables.sh | tee -a 04-populate-variables.log
```
##### 5. Check that the authenticator is working properly
1. Modify the variables at check authenticator script:
```bash
vi  scripts/05-check-authenticator.sh
```
2. Run the script:
```bash
scripts/05-check-authenticator.sh
```
##### 6. Logout from Conjur CLI
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
#### Jenkins branch
##### 1. Login as user jenkins-admin01
- Use the API key as a password from the 01-base.log file for the user jenkins-admin01
```bash
conjur login -i jenkins-admin01
```
##### 2. Load jenkins policy
```bash
conjur policy update -b data/jenkins -f policies/conjur-cloud/02-define-jenkins-branch.yml | tee -a 02-define-jenkins-branch.log
```
##### 3. Logout from Conjur CLI
```Bash
conjur logout
```
#### JWT Authenticator
##### 1. Login to Conjur as admin using the CLI
```bash
conjur  login  -i <username>
```
##### 2. Load the authenticator policy
```Bash
conjur policy update -b conjur/authn-jwt -f policies/conjur-cloud/03-define-jwt-auth.yml | tee -a 03-define-jwt-auth.log
```
##### 3.Enable the authenticator
1. Modify the variables at enable authenticator script:
```bash 
vi scripts/03-enable-authenticator.sh
```
2. Run the script:
```bash
scripts/03-enable-authenticator.sh
```
##### 4. Populate secrets and JWT authenticator variables
1. Modify the variables at populate variables script:
```bash
vi  scripts/04-populate-variables.sh
```
2. Run the script:
```Bash
scripts/04-populate-variables.sh | tee -a 04-populate-variables.log
```
##### 5. Check that the authenticator is working properly
1. Modify the variables at check authenticator script:
```bash
vi  scripts/05-check-authenticator.sh
```
2. Run the script:
```bash
scripts/05-check-authenticator.sh
```
##### 6. Logout from Conjur CLI
```Bash
conjur logout
```
### 3. Jenkins projects
- We will deploy 3 folders and in each 1 project (2 pipelines, 1 freestyle).
- Build the projects according to the folder structure of ***jenkins-projects***.
- The naming convention is: ***[project-type]-[project-name]*** .
- Follow the instructions at each text file.
