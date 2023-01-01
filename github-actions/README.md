
# GitHub Actions integration
This demo uses CyberArk Conjur Secret Fetcher action from GitHub action marketplace.

The action supports authenticating with CyberArk Conjur using host identity and JWT authentication.

This demo will use JWT authentication.

## How does the JWT Authenticator works?
![Conjur JWT authenticator](https://github.com/assafjh/cybr-demos/blob/main/kubernetes-jwt/jwt-authenticator.png?raw=true)

For more details on action, take a look at [CyberArk Conjur Secret Fetcher](https://github.com/marketplace/actions/cyberark-conjur-secret-fetcher)

## 1. Loading Conjur policies
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
### 2. Github branch
#### 1. Login as user github-manager01
- Use the API key as a password from the 01-base.log file for the user jenkins-manager01
```bash
conjur login -i github-manager01
```
#### 2. Load github policy
```bash
conjur policy update -b github -f policies/02-define-github-branch.yml | tee -a 02-define-github-branch.log
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
vi scripts/01_enable_authenticator.sh
```
2. Run the script:
```bash
scripts/01_enable_authenticator.sh
```
#### 5. Populate the secrets and JWT authenticator variables
```Bash
scripts/02_populate_variables.sh | tee -a 02_populate_variables.log
```
### 5. Logout from Conjur CLI
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
