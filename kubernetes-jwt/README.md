# Kubernetes integration using JWT Authenticator
Demo for integration with Kubernetes using JWT authentication.

Included Use-Cases:
- Application that consume secret using the RESTful API.
- Application that consumes secrets from files using Conjur Secrets Provider sidecar.
- Application that consumes secrets from Kubernetes secrets using Conjur Secrets Provider init container.
- Application that consumes secrets from environment parameters using Summon. 
- Application that connects to a Postgres server using Secretless Broker.
- Spring boot based application that refreshes connection when file injected password is changed.

# Table of Contents

<!-- TOC -->

- [Kubernetes integration using JWT Authenticator](#kubernetes-integration-using-jwt-authenticator)
    - [How does the JWT Authenticator works?](#how-does-the-jwt-authenticator-works)
    - [What is Summon?](#what-is-summon)
    - [What is Secretless Broker?](#what-is-secretless-broker)
    - [Instructions](#instructions)
    - [Loading Conjur policies](#loading-conjur-policies)
        - [Conjur Enterprise](#conjur-enterprise)
            - [Root branch](#root-branch)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Update root policy](#update-root-policy)
                - [Logout from Conjur](#logout-from-conjur)
            - [Kubernetes branch](#kubernetes-branch)
                - [Login as user k8s-admin01](#login-as-user-k8s-admin01)
                - [Load kubernetes policy](#load-kubernetes-policy)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
            - [JWT Authenticator](#jwt-authenticator)
                - [Login as user admin01](#login-as-user-admin01)
                - [Load the authenticator policy](#load-the-authenticator-policy)
                - [Enable the authenticator](#enable-the-authenticator)
                - [Populate secrets and JWT authenticator variables](#populate-secrets-and-jwt-authenticator-variables)
                - [Upload demo application binary to Conjur variable](#upload-demo-application-binary-to-conjur-variable)
                - [Check that the authenticator is working properly](#check-that-the-authenticator-is-working-properly)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
        - [Conjur Cloud](#conjur-cloud)
            - [Root branch](#root-branch)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Update data policy](#update-data-policy)
                - [Logout from Conjur](#logout-from-conjur)
            - [Kubernetes branch](#kubernetes-branch)
                - [Login as user k8s-admin01](#login-as-user-k8s-admin01)
                - [Load kubernetes policy](#load-kubernetes-policy)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
            - [JWT Authenticator](#jwt-authenticator)
                - [Login to Conjur as admin using the CLI](#login-to-conjur-as-admin-using-the-cli)
                - [Load the authenticator policy](#load-the-authenticator-policy)
                - [Enable the authenticator](#enable-the-authenticator)
                - [Populate secrets and JWT authenticator variables](#populate-secrets-and-jwt-authenticator-variables)
                - [Upload demo application binary to Conjur variable](#upload-demo-application-binary-to-conjur-variable)
                - [Check that the authenticator is working properly](#check-that-the-authenticator-is-working-properly)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
    - [Deploy demo PostgresSQL Server](#deploy-demo-postgressql-server)
        - [Deploy the server](#deploy-the-server)
        - [Test connectivity to the server](#test-connectivity-to-the-server)
    - [Kubernetes](#kubernetes)
        - [Prepare infrastructure for the deployments](#prepare-infrastructure-for-the-deployments)
            - [Review and modify the manifest](#review-and-modify-the-manifest)
            - [Deploy the create infra manifest](#deploy-the-create-infra-manifest)
        - [Use Case: REST API application](#use-case-rest-api-application)
            - [Deploy the manifest](#deploy-the-manifest)
            - [Check container log](#check-container-log)
            - [Optional: Manually run the app, directly from the container](#optional-manually-run-the-app-directly-from-the-container)
                - [Connect to the container](#connect-to-the-container)
                - [Inside the container, consume a secret by running the script](#inside-the-container-consume-a-secret-by-running-the-script)
        - [Use Case: Conjur Secrets Provider - Sidecar - push to file method](#use-case-conjur-secrets-provider---sidecar---push-to-file-method)
            - [Deploy Manifest](#deploy-manifest)
            - [Check container log](#check-container-log)
            - [Optional: Take a look at the injected file](#optional-take-a-look-at-the-injected-file)
                - [Connect to the demo-application container](#connect-to-the-demo-application-container)
                - [Check that the secrets were pushed to file](#check-that-the-secrets-were-pushed-to-file)
            - [Optional: If you'll update secret3 or secret7, after 10 seconds, the file will be updated](#optional-if-youll-update-secret3-or-secret7-after-10-seconds-the-file-will-be-updated)
                - [Login as user k8s-admin01](#login-as-user-k8s-admin01)
                - [To update secret3, for example, use the below:](#to-update-secret3-for-example-use-the-below)
                - [Wait for the SideCar to re-pull the secrets 10 seconds and recheck the container.](#wait-for-the-sidecar-to-re-pull-the-secrets-10-seconds-and-recheck-the-container)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
        - [Use Case: Conjur Secrets Provider - Init Container - push to secrets method](#use-case-conjur-secrets-provider---init-container---push-to-secrets-method)
            - [Deploy Manifest](#deploy-manifest)
            - [Check container log](#check-container-log)
            - [Optional: Take a look inside the container](#optional-take-a-look-inside-the-container)
                - [Connect to the demo-application container](#connect-to-the-demo-application-container)
                - [Inside the container, check that the secrets were pushed to the environment parameters](#inside-the-container-check-that-the-secrets-were-pushed-to-the-environment-parameters)
            - [See that the secrets were pushed to Kubernetes](#see-that-the-secrets-were-pushed-to-kubernetes)
        - [Use Case: Summon](#use-case-summon)
            - [Deploy Manifest](#deploy-manifest)
            - [Check the container log, see that SECRET2 was echoed](#check-the-container-log-see-that-secret2-was-echoed)
            - [Connect to the demo-application container](#connect-to-the-demo-application-container)
            - [Inside the container, that SECRET2 doesn't exist](#inside-the-container-that-secret2-doesnt-exist)
        - [Use Case: Postgres with Secretless Broker](#use-case-postgres-with-secretless-broker)
            - [Deploy Manifest](#deploy-manifest)
            - [Check the container log](#check-the-container-log)
            - [Optional: Simulate password rotation](#optional-simulate-password-rotation)
                - [Login as user k8s-admin01](#login-as-user-k8s-admin01)
                - [Modify rotate password script](#modify-rotate-password-script)
                - [Run the script](#run-the-script)
                - [Connect to the container](#connect-to-the-container)
                - [Inside the container, connect to the database by running the script](#inside-the-container-connect-to-the-database-by-running-the-script)
                - [Modify reset password script](#modify-reset-password-script)
                - [Run the script](#run-the-script)
                - [Connect to the container](#connect-to-the-container)
                - [Inside the container, connect to the database by running the script](#inside-the-container-connect-to-the-database-by-running-the-script)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)
        - [Use Case: Spring boot application with push to file](#use-case-spring-boot-application-with-push-to-file)
            - [Edit Manifest](#edit-manifest)
            - [Deploy Manifest](#deploy-manifest)
            - [Check the container log](#check-the-container-log)
            - [Optional: Simulate password rotation](#optional-simulate-password-rotation)
                - [Login as user k8s-admin01](#login-as-user-k8s-admin01)
                - [Modify rotate password script](#modify-rotate-password-script)
                - [Run the script](#run-the-script)
                - [Check the container log](#check-the-container-log)
                - [Modify reset password script](#modify-reset-password-script)
                - [Run the script](#run-the-script)
                - [Check the container log](#check-the-container-log)
                - [Logout from Conjur CLI](#logout-from-conjur-cli)

<!-- /TOC -->

## How does the JWT Authenticator works?
![Conjur JWT authenticator](https://github.com/assafjh/cybr-demos/blob/main/kubernetes-jwt/jwt-authenticator.png?raw=true)

## What is Summon?
Summon is a command-line tool that reads a file in secrets.yml format and injects secrets as environment variables into any process. Once the process exits, the secrets are gone.

## What is Secretless Broker?
Secretless Broker lets your applications connect securely to services - without ever having to fetch or manage passwords or keys.

## Instructions
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
#### Kubernetes branch
##### 1. Login as user k8s-admin01
- Use the API key as a password from the 01-base.log file for the user k8s-admin01
```bash
conjur login -i k8s-admin01
```
##### 2. Load kubernetes policy
```bash
conjur policy update -b data/jenkins -f policies/conjur-enterprise/02-define-kubernetes-branch.yml | tee -a 02-define-kubernetes-branch.log
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
- This step will need you to be logged-in to kubectl/oc CLI with admin permissions.
```Bash
scripts/02-populate-variables.sh | tee -a 02-populate-variables.log
```
##### 6. Upload demo application binary to Conjur variable
1. Modify the variables at populate go app script:
```bash
vi  scripts/03-populate-go-app-variable.sh
```
2. Run the script:
```bash
scripts/03-populate-go-app-variable.sh
```
##### 7. Check that the authenticator is working properly
1. Modify the variables at check authenticator script:
```bash
vi  scripts/04-check-authenticator.sh
```
2. Run the script:
```bash
scripts/04-check-authenticator.sh
```
##### 8. Logout from Conjur CLI
```Bash
conjur logout
```
### Conjur Cloud
#### Root branch
##### 1. Login to Conjur as admin using the CLI
```bash
conjur login -i admin
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
##### 1. Login as user k8s-admin01
- Use the API key as a password from the 01-base.log file for the user k8s-admin01
```bash
conjur login -i k8s-admin01
```
##### 2. Load kubernetes policy
```bash
conjur policy update -b data/jenkins -f policies/conjur-cloud/02-define-kubernetes-branch.yml | tee -a 02-define-kubernetes-branch.log
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
- This step will need you to be logged-in to kubectl/oc CLI with admin permissions.
```Bash
scripts/02-populate-variables.sh | tee -a 02-populate-variables.log
```
##### 6. Upload demo application binary to Conjur variable
1. Modify the variables at populate go app script:
```bash
vi  scripts/03-populate-go-app-variable.sh
```
2. Run the script:
```bash
scripts/03-populate-go-app-variable.sh
```
##### 7. Check that the authenticator is working properly
1. Modify the variables at check authenticator script:
```bash
vi  scripts/04-check-authenticator.sh
```
2. Run the script:
```bash
scripts/04-check-authenticator.sh
```
##### 8. Logout from Conjur CLI
```Bash
conjur logout
```
## 2. Deploy demo PostgresSQL Server
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
## 3. Kubernetes
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
kubectl apply -f manifests/01-create-infra.yml
```
### Use Case: REST API application
#### Deploy the manifest
```bash
kubectl apply -f manifests/02-consumer-jwt-appliation.yml
```
#### Check container log
```bash
kubectl get pods -n conjur-jwt --selector=app=jwtsecrets
kubectl logs -n conjur-jwt <pod_name> -c k8s-jwt-app
```
#### Optional: Manually run the app, directly from the container
##### 1. Connect to the container
```bash
kubectl get pods -n conjur-jwt --selector=app=jwtsecrets
kubectl exec -i -t -n conjur-jwt <pod_name> -c k8s-jwt-app -- sh
```
##### 2. Inside the container, consume a secret by running the script
```bash
/scripts/retrieve.sh
```
### Use Case: Conjur Secrets Provider - Sidecar - push to file method
#### Deploy Manifest
```bash
kubectl apply -f manifests/03-push-to-file.yml
```
#### Check container log
```bash
kubectl get pods -n conjur-jwt --selector=app=conjur-push-to-file
kubectl logs -n conjur-jwt <pod_name> -c demo-application
```
#### Optional: Take a look at the injected file
##### 1. Connect to the demo-application container
```bash
kubectl get pods -n conjur-jwt --selector=app=conjur-push-to-file
kubectl exec -i -t -n conjur-jwt <pod_name> -c demo-application -- sh
```
##### 2. Check that the secrets were pushed to file
```bash
cat /opt/secrets/conjur/credentials.yaml
```
#### Optional: If you'll update secret3 or secret7, after 10 seconds, the file will be updated
##### 1. Login as user k8s-admin01
- Use the API key as a password from the 01-base.log file for the user k8s-admin01
```bash
conjur login -i k8s-admin01
```
##### 2. To update secret3, for example, use the below:
```bash
conjur variable set -i data/kubernetes/applications/safe/secret3 -v "new value"
conjur variable set -i data/kubernetes/applications/safe/secret7 -v "new value"
```
##### 3. Wait for the SideCar to re-pull the secrets (10 seconds) and recheck the container.
##### 4. Logout from Conjur CLI
```Bash
conjur logout
```
### Use Case: Conjur Secrets Provider - Init Container - push to secrets method
#### Deploy Manifest
- The manifest will deploy to the NS: 
-- Role: conjur-demo-allow-to-read-secrets
-- RoleBinding: conjur-demo-allow-to-read-secrets-binding
-- ConfigMap: conjur-demo-credentials
-- Deployment: demo-init-container-kubernetes-secrets-jwt
```bash
kubectl apply -f manifests/04-push-to-kubernetes-secrets.yml
```
#### Check container log
```bash
kubectl get pods -n conjur-jwt --selector=app=conjur-push-to-kubernetes-secrets
kubectl logs -n conjur-jwt <pod_name> -c demo-application
```
#### Optional: Take a look inside the container
##### 1. Connect to the demo-application container
```bash
kubectl get pods -n conjur-jwt --selector=app=conjur-push-to-kubernetes-secrets
kubectl exec -i -t -n conjur-jwt <pod_name> -c demo-application -- sh
```
##### 2. Inside the container, check that the secrets were pushed to the environment parameters
```bash
echo $SECRET4
echo $SECRET8
```
#### See that the secrets were pushed to Kubernetes
```bash
kubectl get secret conjur-demo-credentials -n conjur-jwt -o yaml
```
### Use Case: Summon
#### Deploy Manifest
```bash
kubectl apply -f manifests/05-summon.yml
```
#### Check the container log, see that SECRET2 was echoed
```bash
kubectl get pods -n conjur-jwt --selector=app=demo-summon
kubectl logs -n conjur-jwt <pod_name> -c summon-demo-app
```
#### Connect to the demo-application container
```bash
kubectl get pods -n conjur-jwt --selector=app=demo-summon
kubectl exec -i -t -n conjur-jwt <pod_name> -c summon-demo-app -- sh
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
kubectl get pods -n conjur-jwt --selector=app=demo-secretless
kubectl logs -n conjur-jwt <pod_name> -c secretless-demo-app
```
#### Optional: Simulate password rotation
##### 1. Login as user k8s-admin01
- Use the API key as a password from the 01-base.log file for the user k8s-admin01
```bash
conjur login -i k8s-admin01
```
##### 2. Modify rotate password script
```bash
vi scripts/07-rotate-postgres-password.sh
```
##### 3. Run the script
```bash
scripts/07-rotate-postgres-password.sh
```
##### 4. Connect to the container
```bash
kubectl get pods -n conjur-jwt --selector=app=demo-secretless
kubectl exec -i -t -n conjur-jwt <pod_name> -c secretless-demo-app -- sh
```
##### 5. Inside the container, connect to the database by running the script
```bash
/scripts/query-database.sh
```
##### 6. Modify reset password script
```bash
vi scripts/08-reset-postgres-password.sh
```
##### 7. Run the script
```bash
scripts/08-reset-postgres-password.sh
```
##### 8. Connect to the container
```bash
kubectl get pods -n conjur-jwt --selector=app=demo-secretless
kubectl exec -i -t -n conjur-jwt <pod_name> -c secretless-demo-app -- sh
```
##### 9. Inside the container, connect to the database by running the script
```bash
/scripts/query-database.sh
```
##### 10. Logout from Conjur CLI
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
kubectl get pods -n conjur-jwt --selector=app=conjur-push-to-file-springboot
kubectl logs -n conjur-jwt <pod_name> -c spring-boot-demo-app
```
#### Optional: Simulate password rotation
**Note:** Password refresh happens every 10 seconds.
##### 1. Login as user k8s-admin01
- Use the API key as a password from the 01-base.log file for the user k8s-admin01
```bash
conjur login -i k8s-admin01
```
##### 2. Modify rotate password script
```bash
vi scripts/07-rotate-postgres-password.sh
```
##### 3. Run the script
```bash
scripts/07-rotate-postgres-password.sh
```
##### 4. Check the container log
See that the username and password were updated, and that the connection was refreshed.
```bash
kubectl get pods -n conjur-jwt --selector=app=conjur-push-to-file-springboot
kubectl logs -n conjur-jwt <pod_name> -c spring-boot-demo-app
```
##### 5. Modify reset password script
```bash
vi scripts/08-reset-postgres-password.sh
```
##### 6. Run the script
```bash
scripts/08-reset-postgres-password.sh
```
##### 7. Check the container log
See that the username and password were updated, and that the connection was refreshed.
```bash
kubectl get pods -n conjur-jwt --selector=app=conjur-push-to-file-springboot
kubectl logs -n conjur-jwt <pod_name> -c spring-boot-demo-app
```
##### 8. Logout from Conjur CLI
```Bash
conjur logout
```
