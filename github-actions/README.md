
# GitHub Actions integration
This demo uses CyberArk Conjur Secret Fetcher action from GitHub action marketplace.

The action supports authenticating with CyberArk Conjur using host identity and JWT authentication.

This demo will use JWT authentication.

# Table of Contents
<!-- TOC -->

- [GitHub Actions integration](#github-actions-integration)
    - [How does the JWT Authenticator works?](#how-does-the-jwt-authenticator-works)
    - [Loading Conjur policies](#loading-conjur-policies)
        - [Conjur Enterprise](#conjur-enterprise)
            - [Root branch](#root-branch)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Update root policy](#update-root-policy)
                - [Logout from Conjur](#logout-from-conjur)
            - [Github branch](#github-branch)
                - [Login as user github-admin01](#login-as-user-github-admin01)
                - [Load github policy](#load-github-policy)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
            - [JWT Authenticator](#jwt-authenticator)
                - [Login as user admin01](#login-as-user-admin01)
                - [Load the authenticator policy](#load-the-authenticator-policy)
                - [Enable the authenticator](#enable-the-authenticator)
                - [Populate secrets and JWT authenticator variables](#populate-secrets-and-jwt-authenticator-variables)
                - [Check that the authenticator is working properly](#check-that-the-authenticator-is-working-properly)
            - [Logout from Conjur CLI](#logout-from-conjur-cli)
        - [Conjur Cloud](#conjur-cloud)
            - [Data branch](#data-branch)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Update data policy](#update-data-policy)
                - [Logout from Conjur](#logout-from-conjur)
            - [Github branch](#github-branch)
                - [Login as user github-admin01](#login-as-user-github-admin01)
                - [Load github policy](#load-github-policy)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
            - [JWT Authenticator](#jwt-authenticator)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Load the authenticator policy](#load-the-authenticator-policy)
                - [Enable the authenticator](#enable-the-authenticator)
                - [Populate secrets and JWT authenticator variables](#populate-secrets-and-jwt-authenticator-variables)
                - [Check that the authenticator is working properly](#check-that-the-authenticator-is-working-properly)
            - [Logout from Conjur CLI](#logout-from-conjur-cli)
    - [Add conjur-demo workflow to the GitHub repository action](#add-conjur-demo-workflow-to-the-github-repository-action)
        - [Add action secrets to the repository](#add-action-secrets-to-the-repository)
            - [In your repository web page, click on Settings -> Secrets -> Actions](#in-your-repository-web-page-click-on-settings---secrets---actions)
            - [Add the following secrets:](#add-the-following-secrets)
        - [Add the workflow to actions](#add-the-workflow-to-actions)
            - [Go to the repository folder *workflows*](#go-to-the-repository-folder-workflows)
            - [Modify conjur-demo.yml](#modify-conjur-demoyml)
        - [Add conjur-demo.yml to actions](#add-conjur-demoyml-to-actions)
            - [In your repository web page, click on Actions -> New Workflow ->  set up a workflow yourself](#in-your-repository-web-page-click-on-actions---new-workflow----set-up-a-workflow-yourself)
            - [Paste the contents of workflows/conjur-demo.yml](#paste-the-contents-of-workflowsconjur-demoyml)
            - [Commit the file](#commit-the-file)
        - [Run the workflow](#run-the-workflow)
            - [Modify the file dummy-file and commit](#modify-the-file-dummy-file-and-commit)
            - [In your repository web page, click on Actions and make sure the workflow ran](#in-your-repository-web-page-click-on-actions-and-make-sure-the-workflow-ran)

<!-- /TOC -->

## How does the JWT Authenticator works?
![Conjur JWT authenticator](https://github.com/assafjh/cybr-demos/blob/main/kubernetes-jwt/jwt-authenticator.png?raw=true)

For more details on action, take a look at [CyberArk Conjur Secret Fetcher Action](https://github.com/marketplace/actions/cyberark-conjur-secret-fetcher-action)

## 1. Loading Conjur policies
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
#### Github branch
##### 1. Login as user github-admin01
- Use the API key as a password from the 01-base.log file for the user jenkins-admin01
```bash
conjur login -i github-admin01
```
##### 2. Load github policy
```bash
conjur policy update -b data/github -f policies/conjur-enterprise/02-define-github-branch.yml | tee -a 02-define-github-branch.log
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
##### 4. Enable the authenticator
- This step will work from the Conjur Leader VM only.
1. Modify the variables at enable authenticator script:
```bash 
vi scripts/01-enable-authenticator.sh
```
2. Run the script:
```bash
scripts/01-enable-authenticator.sh
```
##### 5. Populate secrets and JWT authenticator variables
```Bash
scripts/02-populate-variables.sh | tee -a 02-populate-variables.log
```
##### 6. Check that the authenticator is working properly
 1. Modify the variables at enable authenticator script:
```bash 
vi scripts/03-check-authenticator.sh
```
2. Run the script:
```bash
scripts/03-check-authenticator.sh
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
#### Github branch
##### 1. Login as user github-admin01
- Use the API key as a password from the 01-base.log file for the user jenkins-admin01
```bash
conjur login -i github-admin01
```
##### 2. Load github policy
```bash
conjur policy update -b data/github -f policies/conjur-cloud/02-define-github-branch.yml | tee -a 02-define-github-branch.log
```
##### 3. Logout from Conjur CLI
```Bash
conjur logout
```
#### JWT Authenticator
##### 1. Login to Conjur as admin using the CLI
```bash
conjur login -i <username>
```
##### 2. Load the authenticator policy
```Bash
conjur policy update -b conjur/authn-jwt -f policies/conjur-cloud/03-define-jwt-auth.yml | tee -a 03-define-jwt-auth.log
```
##### 4. Enable the authenticator
1. Modify the variables at enable authenticator script:
```bash 
vi scripts/01-enable-authenticator.sh
```
2. Run the script:
```bash
scripts/01-enable-authenticator.sh
```
##### 5. Populate secrets and JWT authenticator variables
```Bash
scripts/02-populate-variables.sh | tee -a 02-populate-variables.log
```
##### 6. Check that the authenticator is working properly
 1. Modify the variables at enable authenticator script:
```bash 
vi scripts/03-check-authenticator.sh
```
2. Run the script:
```bash
scripts/03-check-authenticator.sh
```
#### Logout from Conjur CLI
```Bash
conjur logout
```
## 3. Add conjur-demo workflow to the GitHub repository action
### 1. Add action secrets to the repository
#### 1. In your repository web page, click on Settings -> Secrets -> Actions 
A quick link:
```bash
https://github.com/$USERNAME/$REPOSIROTY/settings/secrets/actions
```

#### 2. Add the following secrets:
- `CONJUR_AUTHN_ID`- For this demo, the Conjur authenticator ID is: **github1**
- `CONJUR_PUBLIC_KEY` - Add Conjur public key
- `CONJUR_URL` - Add Conjur FQDN (Including schema and port)

### 2. Add the workflow to actions
The demo work flow we are going to load, ***conjur-demo*** will run any time something will be pushed to the folder ***github-actions***
#### 1. Go to the repository folder *workflows*
#### 2.  Modify conjur-demo.yml
```bash
...
# Line #9: Change the trigger folder of the workflow:
      - $FOLDER/**
...
# Line #15: Change action version to the latest one:
        uses: infamousjoeg/conjur-action@$TAG
...
# Line #18: Change the Conjur account to match your environment:
        account: $ACCOUNT
```

### 3. Add conjur-demo.yml to actions
#### 1. In your repository web page, click on Actions -> New Workflow ->  set up a workflow yourself
A quick link:
```bash
 https://github.com/$USERNAME/$REPOSITORY/new/main?filename=.github%2Fworkflows%2Fmain.yml&workflow_template=blank
```
#### 2. Paste the contents of workflows/conjur-demo.yml
#### 3. Commit the file

### 4. Run the workflow
#### 1. Modify the file dummy-file and commit
#### 2. In your repository web page, click on Actions and make sure the workflow ran 
A quick link:
```bash
 https://github.com/$USERNAME/$REPOSITORY/actions
```
