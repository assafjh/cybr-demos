# Kubernetes integration using Cert Authenticator
Demo for integration with Kubernetes using Certificate authentication.

Included Use-Cases:
- Application that consumes secrets from files using Conjur Secrets Provider sidecar.
- Application that consumes secrets from Kubernetes secrets using Conjur Secrets Provider init container.
- Application that consumes secrets from environment parameters using Summon. 
- Application that connects to a Postgres server using Secretless Broker.
- Spring boot based application that refreshes connection when file injected password is changed.
- Application that consumes secrets from RESTful API using Conjur authenticator client init container.

## How does the Kubernetes Cert Authenticator works?
![Conjur k8s cert authenticator](https://github.com/assafjh/cybr-demos/blob/main/kubernetes-cert/k8s-cert-authenticator.png?raw=true)

### More Info on the authenticator
https://github.com/cyberark/conjur-authn-k8s-client

## What is Summon?
Summon is a command-line tool that reads a file in secrets.yml format and injects secrets as environment variables into any process. Once the process exits, the secrets are gone.

## What is Secretless Broker?
Secretless Broker lets your applications connect securely to services - without ever having to fetch or manage passwords or keys.

## Instructions

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

#### Kubernetes branch

##### Login as user k8s-admin01
- Use the API key as a password from the 01-base.log file for the user k8s-admin01
```bash
conjur login -i k8s-admin01
```

##### Load kubernetes policy
```bash
conjur policy update -b data/kubernetes -f policies/conjur-enterprise/02-define-kubernetes-branch.yml | tee -a 02-define-kubernetes-branch.log
```

##### Logout from Conjur CLI
```Bash
conjur logout
```

#### Kubernetes Cert Authenticator

##### Login as user admin01
 - Use the API key as a password from the 01-base.log file for the user admin01
```bash
conjur login -i admin01
```

##### Load the authenticator policy
```Bash
conjur policy update -b root -f policies/conjur-enterprise/03-define-k8s-cert-auth.yml | tee -a 03-define-k8s-cert-auth.log
```

##### Enable the authenticator
- This step will work from the Conjur Leader VM only.
1. Modify the variables at enable authenticator script:
```bash 
vi scripts/01-enable-authenticator.sh
```
2. Run the script:
```bash
scripts/01-enable-authenticator.sh
```

##### Populate secrets and k8s cert authenticator variables
- This step will need you to be logged-in to kubectl/oc CLI with admin permissions.
1. Modify the variables at populate variables script:
```bash
vi  scripts/02-populate-variables.sh
```
2. Run the script:
```Bash
scripts/02-populate-variables.sh | tee -a 02-populate-variables.log
```

##### Upload demo application binary to Conjur variable
1. Modify the variables at populate go app script:
```bash
vi  scripts/03-populate-go-app-variable.sh
```
2. Run the script:
```bash
scripts/03-populate-go-app-variable.sh
```

##### Validate that the values provided to the authenticator are correct
- The script below will try to authenticate to *$KUBE_API*/healthz using the variables we have loaded.
```Bash
scripts/04-validate-connectivity-to-kubernetes-api.sh
```

##### Logout from Conjur CLI
```Bash
conjur logout
```

### Conjur Cloud

#### Root branch

##### Login to Conjur as admin using the CLI
```bash
conjur login -i admin
```

##### Update data policy
```bash
conjur policy update -b data -f policies/conjur-cloud/01-base.yml | tee -a 01-base.log
```

##### Logout from Conjur
```Bash
conjur logout
```

#### Kubernetes branch

##### Login as user k8s-admin01
- Use the API key as a password from the 01-base.log file for the user k8s-admin01
```bash
conjur login -i k8s-admin01
```

##### Load kubernetes policy
```bash
conjur policy update -b data/kubernetes -f policies/conjur-cloud/02-define-kubernetes-branch.yml | tee -a 02-define-kubernetes-branch.log
```

##### Logout from Conjur CLI
```Bash
conjur logout
```

#### Kubernetes Cert Authenticator

##### Login to Conjur as admin using the CLI
```bash
conjur login -i <username>
```

##### Load the authenticator policy
```Bash
conjur policy update -b conjur/authn-jwt -f policies/conjur-cloud/03-define-k8s-cert-auth.yml | tee -a 03-define-k8s-cert-auth.log
```

##### Enable the authenticator
- This step will work from the Conjur Leader VM only.
1. Modify the variables at enable authenticator script:
```bash 
vi scripts/01-enable-authenticator.sh
```
2. Run the script:
```bash
scripts/01-enable-authenticator.sh
```

##### Populate secrets and JWT authenticator variables
- This step will need you to be logged-in to kubectl/oc CLI with admin permissions.
1. Modify the variables at populate variables script:
```bash
vi  scripts/02-populate-variables.sh
```
2. Run the script:
```Bash
scripts/02-populate-variables.sh | tee -a 02-populate-variables.log
```

##### Upload demo application binary to Conjur variable
1. Modify the variables at populate go app script:
```bash
vi  scripts/03-populate-go-app-variable.sh
```
2. Run the script:
```bash
scripts/03-populate-go-app-variable.sh
```

##### Validate that the values provided to the authenticator are correct
- The script below will try to authenticate to *$KUBE_API*/healthz using the variables we have loaded.
```Bash
scripts/04-validate-connectivity-to-kubernetes-api.sh
```

##### Logout from Conjur CLI
```Bash
conjur logout
```

## Deploy demo PostgresSQL Server
Use cases demoing Secretless Broker and Spring Boot based app are connecting to a demo 
Postgres database. 
The demo server is meant to be deployed on Podman/Docker.

### Deploy the server
1. Modify the variables at deployment script:
```bash
vi  scripts/05-deploy-postgres-server.sh
```
2. Run the script:
```bash
scripts/05-deploy-postgres-server.sh
```

### Test connectivity to the server
1. Modify the variables at test connectivity script:
```bash
vi  scripts/06-test-connectivity-to-postgres
```
2. Run the script:
```bash
scripts/06-test-connectivity-to-postgres
```

## Kubernetes
- For the steps below we will need Kubernetes/OCP admin permissions.
- If using OCP, change kubectl to oc.

### Prepare infrastructure for the deployments

#### Review and modify the manifest
- The manifest will deploy: 
-- NS: conjur-cert
-- SA: conjur-demo-acct
-- Role: conjur-role
-- RoleBinding: conjur-role-binding
-- ConfigMap: conjur-connect
- The ConfigMap needs to be modified
-- lines #61, #62: change <CONJUR_FQDN> to your Conjur host and port.
-- line #65: change <CONJUR_PUB_KEY> to Conjur public key.

#### Deploy the create infra manifest
```bash
kubectl apply -f manifests/01-create-infra.yml
```

### Check that the token controller create a token secret for the Conjur service account
```bash
kubectl get secrets -n conjur-cert
``` 

#### In case the secret doesn't exist, load the manifest below
```bash
kubectl apply -f manifests/02-create-api-token-for-service-account.yml
``` 

### Use Case: Conjur Secrets Provider - Sidecar - push to file method

#### Deploy Manifest
```bash
kubectl apply -f manifests/03-push-to-file.yml
```

#### Check container log
```bash
kubectl get pods -n conjur-cert --selector=app=conjur-push-to-file
kubectl logs -n conjur-cert <pod_name> -c demo-application
```

#### Optional: Take a look at the injected file

##### Connect to the demo-application container
```bash
kubectl get pods -n conjur-cert --selector=app=conjur-push-to-file
kubectl exec -i -t -n conjur-cert <pod_name> -c demo-application -- sh
```

##### Check that the secrets were pushed to file
```bash
cat /opt/secrets/conjur/credentials.yaml
```

#### Optional: If you'll update secret3 or secret7, after 10 seconds, the file will be updated

##### Login as user k8s-admin01
- Use the API key as a password from the 01-base.log file for the user k8s-admin01
```bash
conjur login -i k8s-admin01
```

##### To update secret3, for example, use the below:
```bash
conjur variable set -i data/kubernetes/applications/safe/secret3 -v "new value"
conjur variable set -i data/kubernetes/applications/safe/secret7 -v "new value"
```

##### Wait for the SideCar to re-pull the secrets (10 seconds) and recheck the container.

##### Logout from Conjur CLI
```Bash
conjur logout
```

### Use Case: Conjur Secrets Provider - Init Container - push to secrets method

#### Deploy Manifest
- The manifest will deploy to the NS: 
-- Role: conjur-demo-allow-to-read-secrets
-- RoleBinding: conjur-demo-allow-to-read-secrets-binding
-- ConfigMap: conjur-demo-credentials
-- Deployment: demo-init-container-kubernetes-secrets
```bash
kubectl apply -f manifests/04-push-to-kubernetes-secrets.yml
```

#### Check container log
```bash
kubectl get pods -n conjur-cert --selector=app=conjur-push-to-kubernetes-secrets
kubectl logs -n conjur-cert <pod_name> -c demo-application
```

#### Optional: Take a look inside the container

##### Connect to the demo-application container
```bash
kubectl get pods -n conjur-cert --selector=app=conjur-push-to-kubernetes-secrets
kubectl exec -i -t -n conjur-cert <pod_name> -c demo-application -- sh
```

##### Inside the container, check that the secrets were pushed to the environment parameters
```bash
echo $SECRET4
echo $SECRET8
```

#### See that the secrets were pushed to Kubernetes
```bash
kubectl get secret conjur-demo-credentials -n conjur-cert -o yaml
```

### Use Case: Summon

#### Deploy Manifest
```bash
kubectl apply -f manifests/05-summon.yml
```

#### Check the container log, see that SECRET2 was echoed
```bash
kubectl get pods -n conjur-cert --selector=app=demo-summon
kubectl logs -n conjur-cert <pod_name> -c summon-demo-app
```

#### Connect to the demo-application container
```bash
kubectl get pods -n conjur-cert --selector=app=demo-summon
kubectl exec -i -t -n conjur-cert <pod_name> -c summon-demo-app -- sh
```

#### Inside the container, that SECRET2 doesn't exist
```bash
env | grep SECRET2
# OR
echo $SECRET2
```

### Use Case: Postgres with Secretless Broker

#### Deploy Manifest
```bash
kubectl apply -f manifests/06-deploy-secretless
```

#### Check the container log
```bash
kubectl get pods -n conjur-cert --selector=app=demo-secretless
kubectl logs -n conjur-cert <pod_name> -c secretless-demo-app
```

#### Optional: Simulate password rotation

##### Login as user k8s-admin01
- Use the API key as a password from the 01-base.log file for the user k8s-admin01
```bash
conjur login -i k8s-admin01
```

##### Modify rotate password script
```bash
vi scripts/07-rotate-postgres-password.sh
```

##### Run the script
```bash
scripts/07-rotate-postgres-password.sh
```

##### Connect to the container
```bash
kubectl get pods -n conjur-cert --selector=app=demo-secretless
kubectl exec -i -t -n conjur-cert <pod_name> -c secretless-demo-app -- sh
```

##### Inside the container, connect to the database by running the script
```bash
/scripts/query-database.sh
```

##### Modify reset password script
```bash
vi scripts/08-reset-postgres-password.sh
```

##### Run the script
```bash
scripts/08-reset-postgres-password.sh
```

##### Connect to the container
```bash
kubectl get pods -n conjur-cert --selector=app=demo-secretless
kubectl exec -i -t -n conjur-cert <pod_name> -c secretless-demo-app -- sh
```

##### Inside the container, connect to the database by running the script
```bash
/scripts/query-database.sh
```

##### Logout from Conjur CLI
```Bash
conjur logout
```

### Use Case: Spring boot application with push to file

#### Edit Manifest
```bash
vi manifests/07-push-to-file-springboot.yml
```

#### Deploy Manifest
```bash
kubectl apply -f manifests/07-push-to-file-springboot.yml
```

#### Check the container log
```bash
kubectl get pods -n conjur-cert --selector=app=conjur-push-to-file-springboot
kubectl logs -n conjur-cert <pod_name> -c spring-boot-demo-app
```

#### Optional: Simulate password rotation
**Note:** Password refresh happens every 10 seconds.

##### Login as user k8s-admin01
- Use the API key as a password from the 01-base.log file for the user k8s-admin01
```bash
conjur login -i k8s-admin01
```

##### Modify rotate password script
```bash
vi scripts/07-rotate-postgres-password.sh
```

##### Run the script
```bash
scripts/07-rotate-postgres-password.sh
```

##### Check the container log
See that the username and password were updated, and that the connection was refreshed.
```bash
kubectl get pods -n conjur-cert --selector=app=conjur-push-to-file-springboot
kubectl logs -n conjur-cert <pod_name> -c spring-boot-demo-app
```

##### Modify reset password script
```bash
vi scripts/08-reset-postgres-password.sh
```

##### Run the script
```bash
scripts/08-reset-postgres-password.sh
```

##### Check the container log
See that the username and password were updated, and that the connection was refreshed.
```bash
kubectl get pods -n conjur-cert --selector=app=conjur-push-to-file-springboot
kubectl logs -n conjur-cert <pod_name> -c spring-boot-demo-app
```

##### Logout from Conjur CLI
```Bash
conjur logout
```

### Use Case: Consuming a secret using REST API

#### Deploy Manifest
```bash
kubectl apply -f manifests/08-rest-api
```

#### Check the container log
```bash
kubectl get pods -n conjur-cert --selector=app=restsecrets
kubectl logs -n conjur-cert <pod_name> -c k8s-rest-api-app
```