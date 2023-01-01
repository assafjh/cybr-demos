# GitLab CI integration
This demo shows how to pull secrets from Conjur in GitLab CI.

This demo will authenticate to Conjur using GitLab's auto generated JWT  stored under environment parameter: `CI_JOB_JWT` .

#### Use cases:
1. Job that uses REST API to pull a secret from Conjur.
2. Job that uses Summon to pull a secret from Conjur.

## How does the JWT Authenticator works?
![Conjur JWT authenticator](https://github.com/assafjh/cybr-demos/blob/main/kubernetes-jwt/jwt-authenticator.png?raw=true)
- For more details on GitLab CI Predefined variables, please refer to: [GitLab CI: Predefined variables reference](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html)

- For an example GitLab CI payload, take a look at the file: `payload-example.json`

- For more details on Summon, take a look at [CyberArk Summon](https://cyberark.github.io/summon/)

## 1. Deploy GitLab Server
**Note**: The below will deploy GitLab CE server
If needed, deploy a GitLab server instance:
1. Modify the variables at the deployment script:
```bash 
vi scripts/01-deploy-gitlab-server.sh
```
2. Run the script:
```bash
scripts/01-deploy-gitlab-server.sh
```

## 2. Deploy GitLab Runner
**Note**: The below will deploy a Shell Executor with the tag "conjur-demo"
1. Modify the variables at the deployment script:
```bash 
vi scripts/02-deploy-gitlab-runner.sh
```
2. Run the script:
```bash
scripts/02-deploy-gitlab-runner.sh
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
conjur policy update -b root -f policies/01-base.yml | tee -a 01-base.log
```
#### 3. Logout from Conjur
```Bash
conjur logout
```
### 2. GitLab branch
#### 1. Login as user gitlab-manager01
- Use the API key as a password from the 01-base.log file for the user jenkins-manager01
```bash
conjur login -i gitlab-manager01
```
#### 2. Load gitlab policy
- Before running the export commands below, modify them with the correct values.
```bash
# How to get Namespace Path: GET $GITLAB_SERVER/api/v4/namespaces
# Select the path that belongs to "GitLab Instance"
export NAMESPACE_PATH=<NAME_SPACE_PATH>
envsubst < policies/02-define-gitlab-branch.yml > 02-define-gitlab-branch.yml
conjur policy update -b gitlab -f 02-define-gitlab-branch.yml | tee -a 02-define-gitlab-branch.log
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
vi scripts/03-enable-authenticator.sh
```
2. Run the script:
```bash
scripts/03-enable-authenticator.sh
```
#### 5. Populate the secrets and JWT authenticator variables
1. Modify the variables at populate variables script:
```bash 
vi scripts/04-populate-variables.sh
```
2. Run the script:
```Bash
scripts/04-populate-variables.sh | tee -a 04-populate-variables.log
```
### 5. Logout from Conjur CLI
```Bash
conjur logout
```

## 4. Create a demo project at GitLab instance
#### 1. At Instance Dashboard screen, click "New Project"
#### 2. Select "Create Blank Project"
#### 3. Fill in a project name (I have used "Demo")
#### 4. Click Create Project.

## 4. Upload .gitlab-ci.yml to the project
### 1. Modify line #3 with the correct Conjur URL
```bash
vi jobs/.gitlab-ci.yml
```
For example
```yml
...
CONJUR_APPLIANCE_URL: https://example.conjur.server:8443
...
```
### 2. Upload the file jobs/.gitlab-ci.yml to the project root

## 5. Check the project's job results
### 1. At GitLab UI, click CI/CD -> Jobs
### 2. Take a look at the jobs:
- retrieve-variable-via-rest
- retrieve-variable-via-summon
