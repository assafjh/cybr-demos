# Kubernetes integration using JWT Authenticator
Demo for integration with Kubernetes using JWT authentication.

Four Use cases are included:
- Application that consume secret using the RESTful API.
- Application that consumes secrets from files using Conjur Secrets Provider sidecar.
- Application that consumes secrets from Kubernetes secrets using Conjur Secrets Provider init container.
- Application that consumes secrets from environment parameters using Summon. 

## How does the JWT Authenticator works?
![Conjur JWT authenticator](https://github.com/assafjh/cybr-demos/blob/main/kubernetes-jwt/jwt-authenticator.png?raw=true)

## What is Summon?
Summon is a command-line tool that reads a file in secrets.yml format and injects secrets as environment variables into any process. Once the process exits, the secrets are gone.

## Instructions
## 1. Loading Conjur policies
- Policy statements are loaded into either the Conjur  root policy branch or a policy branch under root
- Per best practices, most policies will be created in branches off of root. 
- Branches have the following advantages: better organizing, help policy isolation for least privilege assignments, enforce RBAC, allowing relevant users to manage their own policy.
- The demo uses an organizational structure that can be found under the folder ***policies***.
#### Root branch
##### 1. Login to Conjur as admin using the CLI
```bash
conjur login -i admin
```
##### 2. Load root policy
```bash
conjur policy update -b root -f policies/01-base | tee -a 01-base.log
```
##### 3. Logout from Conjur
```Bash
conjur logout
```
#### Kubernetes branch
##### 1. Login as user k8s-manager01
- Use the API key as a password from the 01-base.log file for the user k8s-manager01
```bash
conjur login -i k8s-manager01
```
##### 2. Load kubernetes policy
```bash
conjur policy update -b jenkins -f policies/02-define-kubernetes-branch.yml | tee -a 02-define-kubernetes-branch.log
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
conjur policy update -b root -f policies/03-define-jwt-auth.yml | tee -a 03-define-jwt-auth.log
```
##### 4. Enable the authenticator
- This step will work from the Conjur Leader VM only.
1. Modify the variables at enable authenticator script:
```bash 
vi scripts/01_enable_authenticator.sh
```
2. Run the script:
```bash
scripts/01_enable_authenticator.sh
```
##### 5. Populate the secrets and JWT authenticator variables
- This step will need you to be logged-in to kubectl/oc CLI with admin permissions.
```Bash
scripts/02_populate_variables.sh | tee -a 02_populate_variables.log
```
##### 6. Logout from Conjur CLI
```Bash
conjur logout
```

## 2. Kubernetes
- For the steps below we will need Kubernetes/OCP admin permissions.
- If using OCP, change kubectl to oc.
### Prepare infrastructure for the deployments
#### 1. Review and modify the manifest
- The manifest will deploy: 
-- NS: conjur-jwt
-- SA: conjur-demo-acct
-- Role: conjur-role
-- RoleBinding: conjur-role-binding
-- ConfigMap: conjur-connect
- The ConfigMap needs to be modified
-- lines #61, #62: change <CONJUR_FQDN> to your Conjur host and port.
-- line #65: change <CONJUR_PUB_KEY> to Conjur public key.
#### 2. Deploy the create infra manifest
```bash
kubectl apply -f manifests/01_create_infra.yml
```
### Use Case: REST API application
#### 1. Deploy the manifest
```bash
kubectl apply -f manifests/02_consumer_jwt_appliation.yml
```
#### 2. Connect to the container
```bash
kubectl get pods -n conjur-jwt --selector=app=jwtsecrets
kubectl exec -i -t -n conjur-jwt <pod_name> -c k8s-jwt-app -- sh -c "bash"
```
#### 3. Inside the container, consume a secret by running the script
```bash
/scripts/retrieve.sh
```
### Use Case: Conjur Secrets Provider - Sidecar - push to file method
#### 1. Deploy Manifest
```bash
kubectl apply -f manifests/03_push_to_file.yml
```
#### 2. Connect to the demo-application container
```bash
kubectl get pods -n conjur-jwt --selector=app=conjur-push-to-file
kubectl exec -i -t -n conjur-jwt <pod_name> -c demo-application -- sh -c "bash"
```
#### 3. Inside the container, check that the secrets were pushed to file
```bash
cat /opt/secrets/conjur/credentials.yaml
```
#### 4. Optional: If you'll update secret3 or secret7, after 10 seconds, the file will be updated
##### 4a. Login as user k8s-manager01
- Use the API key as a password from the 01-base.log file for the user k8s-manager01
```bash
conjur login -i k8s-manager01
```
##### 4b. To update secret3, for example, use the below:
```bash
conjur variable set -i kubernetes/applications/safe/secret3 -v "new value"
conjur variable set -i kubernetes/applications/safe/secret7 -v "new value"
```
##### 4c. Wait for the SideCar to re-pull the secrets (10 seconds) and recheck the container.
##### 4d. Logout from Conjur CLI
```Bash
conjur logout
```
### Use Case: Conjur Secrets Provider - Init Container - push to secrets method
#### 1. Deploy Manifest
- The manifest will deploy to the NS: 
-- Role: conjur-demo-allow-to-read-secrets
-- RoleBinding: conjur-demo-allow-to-read-secrets-binding
-- ConfigMap: conjur-demo-credentials
-- Deployment: demo-init-container-kubernetes-secrets-jwt
```bash
kubectl apply -f manifests/04_push_to_file.yml
```
#### 2. Connect to the demo-application container
```bash
kubectl get pods -n conjur-jwt --selector=app=conjur-push-to-kubernetes-secrets
kubectl exec -i -t -n conjur-jwt <pod_name> -c demo-application -- sh -c "bash"
```
#### 3. Inside the container, check that the secrets were pushed to the environment parameters
```bash
echo $SECRET4
echo $SECRET8
```
#### 4. See that the secrets were pushed to Kubernetes
```bash
kubectl get secret conjur-demo-credentials -n conjur-jwt -o yaml
```
### Use Case: Summon
#### 1. Deploy Manifest
```bash
kubectl apply -f manifests/05_summon.yml
```
#### 2. Check the container log, see that SECRET2 was echoed
```bash
kubectl get pods -n conjur-jwt --selector=app=demo-summon
kubectl logs -n conjur-jwt <pod_name> -c summon-demo-app
```
#### 3. Connect to the demo-application container
```bash
kubectl get pods -n conjur-jwt --selector=app=demo-summon
kubectl exec -i -t -n conjur-jwt <pod_name> -c summon-demo-app -- sh -c "sh"
```
#### 4. Inside the container, that SECRET2 doesn't exist
```bash
env | grep SECRET2
# OR
echo $SECRET2
```
