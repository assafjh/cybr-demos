# Kubernetes ESO Integration

Demo for integration with Kubernetes using ESO.

**External Secrets Operator** is a Kubernetes operator that integrates external secret management systems.

The operator reads information from external APIs and automatically injects the values into a [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/).

For more information: [External Secrets](https://external-secrets.io/)

## 1. Install ESO
It is assumed that helm is installed.
```bash
scripts/01-install-eso.sh
```

## 2. Load Conjur policies
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
#### Kubernetes branch
##### 1. Login as user kubernetes-admin01
- Use the API key as a password from the 01-base.log file for the user kubernetes-admin01
```bash
conjur login -i kubernetes-admin01
```
#### 2. Load kubernetes policy
```bash
conjur policy update -b data/kubernetes -f policies/conjur-enterprise/02-define-kubernetes-branch.yml | tee -a 02-define-kubernetes-branch.log
```
#### 3. Populate secret variables
1. Modify the variables at populate variables script:
```bash
vi  scripts/02-populate-variables.sh
```
2. Run the script:
```Bash
scripts/02-populate-variables | tee -a 02-populate-variables.log
```
#### 4. Logout from Conjur CLI
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
#### Kubernetes branch
##### 1. Login as user kubernetes-admin01
- Use the API key as a password from the 01-base.log file for the user kubernetes-admin01
```bash
conjur login -i kubernetes-admin01
```
#### 2. Load kubernetes policy
```bash
conjur policy update -b data/kubernetes -f policies/conjur-cloud/02-define-kubernetes-branch.yml | tee -a 02-define-kubernetes-branch.log
```
#### 3. Populate secret variables
```Bash
scripts/03-populate-variables | tee -a 03-populate-variables.log
```
#### 4. Logout from Conjur CLI
```Bash
conjur logout
```
## 3. Kubernetes
It assumed that you are connected with admin permissions to a Kubernetes cluster
### Create external secret store
#### 1. Modify create store manifest
- Line #10: API Key value can be found at `02-define-kubernetes-branch.log`
- Line #22: Conjur URL
- Line #24: If not needed, can be commented out. Value can be found at `scripts/one-line-conjur-cert.b64`
```bash
vi manifests/01-create-store.yml
```
#### 2. Apply the manifest
```bash
kubectl apply -f manifests/01-create-store.yml
```
### Create external secrets
```bash
kubectl apply -f manifests/01-create-secrets.yml
```
### Consume external secrets
```bash
scripts/03-print-secrets.sh
```
