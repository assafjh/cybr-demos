# Kubernetes Certificate authentication based follower
Instructions for deploying a demo certificate authentication based follower inside a Kubernetes cluster.

## How does the Kubernetes Cert Authenticator works?

![Conjur k8s cert authenticator](https://github.com/assafjh/cybr-demos/blob/main/kubernetes-follower/cert-based/k8s-cert-authenticator.png?raw=true)
## Follower deployment flow
![Cert-based authn deployment flow](https://github.com/assafjh/cybr-demos/blob/main/kubernetes-follower/cert-based/follower-cert-based-flow.png?raw=true)

## Instructions
### 1. Loading Conjur policies
- Policy statements are loaded into either the Conjur  root policy branch or a policy branch under root
- Per best practices, most policies will be created in branches off of root. 
- Branches have the following advantages: better organizing, help policy isolation for least privilege assignments, enforce RBAC, allowing relevant users to manage their own policy.
- The demo uses an organizational structure that can be found under the folder ***policies***.
#### Root branch
##### 1. Login to Conjur as admin using the CLI
```bash
conjur login -i admin
```
##### 2. Update root policy
```bash
conjur policy update -b root -f policies/01-base.yml | tee -a 01-base.log
```
##### 3. Logout from Conjur
```Bash
conjur logout
```
#### Kubernetes branch
##### 1. Login as user k8s-admin01
- Use the API key as a password from the 01-base.log file for the user k8s-admin01
```bash
conjur login -i k8s-admin01
```
##### 2. Load kubernetes policy
```bash
conjur policy update -b data/kubernetes -f policies/02-define-kubernetes-branch.yml | tee -a 02-define-kubernetes-branch.log
```
##### 3. Logout from Conjur CLI
```Bash
conjur logout
```
#### Kubernetes Cert Authenticator
##### 1. Login as user admin01
 - Use the API key as a password from the 01-base.log file for the user admin01
```bash
conjur login -i admin01
```
##### 2. Load the authenticator policy
```Bash
conjur policy update -b root -f policies/03-define-k8s-cert-auth.yml | tee -a 03-define-k8s-cert-auth.log
```
##### 3. Enable the authenticator
- This step will work from the Conjur Leader VM only.
1. Modify the variables at enable authenticator script:
```bash 
vi scripts/01-enable-authenticator.sh
```
2. Run the script:
```bash
scripts/01-enable-authenticator.sh
```
##### 4. Populate the k8s cert authenticator variables
- This step will need you to be logged-in to kubectl/oc CLI with admin permissions.
1. Modify the variables at populate variables script:
```bash 
vi scripts/02-populate-variables.sh
```
2. Run the script:
```Bash
scripts/02-populate-variables.sh | tee -a 02-populate-variables.log
```
##### 5. Validate that the values provided to the authenticator are correct
- The script below will try to authenticate to *$KUBE_API*/healthz using the variables we have loaded.
```Bash
scripts/03-validate-connectivity-to-kubernetes-api.sh
```
#### Seed Generator service
##### 1. Enable seed generation
```Bash
conjur policy update -b root -f policies/04-enable-seed-generation.yml | tee -a 04-enable-seed-generation.log
```
##### 2. Logout from Conjur CLI
```Bash
conjur logout
```

### 2. Kubernetes
- For the steps below we will need Kubernetes/OCP admin permissions.
- If using OCP, change kubectl to oc.
#### Prepare infrastructure for the deployments
##### 1. Review and modify the manifest
- The manifest will deploy: 
-- NS: conjur-cert-follower
-- SA: conjur-demo-acct
-- Role: conjur-role
-- RoleBinding: conjur-role-binding
-- Service: conjur-follower
-- ConfigMap: conjur-connect
- The ConfigMap needs to be modified
-- lines #75, #76: change <CONJUR_FQDN> to your Conjur host and port.
-- line #79: if needed, update the <CONJUR_AUTHENTICATORS> with the enabled authenticators for the follower
-- line #82: change <CONJUR_PUB_KEY> to Conjur public key.
##### 2. Deploy the create infra manifest
```bash
kubectl apply -f manifests/01-create-infra.yml
```
##### 3. Check that the token controller created a token secret for the Conjur service account
```bash
kubectl get secrets -n conjur-cert-follower
``` 
##### 4. In case the secret doesn't exist, load the manifest below
```bash
kubectl apply -f manifests/02-create-api-token-for-service-account.yml
``` 
#### Deploy the follower
##### 1. Update the manifest at line #60 with the conjur appliance image location
```bash
vi manifests/03-deploy-follower.yml
```
Example: 
```yaml
image: mycorp-registry/conjur-appliance:version
```
##### 2. Deploy Manifest
```bash
kubectl apply -f manifests/03-deploy-follower.yml
``` 
