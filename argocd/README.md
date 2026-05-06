# ArgoCD + Conjur Cloud — Secrets Injection via ArgoCD Vault Plugin

Demonstrates GitOps-native secrets management: ArgoCD syncs a Kubernetes manifest that contains `<path:...>` placeholders instead of real secrets. The ArgoCD Vault Plugin (AVP), running as a sidecar in `argocd-repo-server`, resolves those placeholders against Conjur Cloud at sync time and writes a Kubernetes Secret — no secrets ever committed to Git.

## Architecture

```
ArgoCD Application (demo-app/application.yaml)
  └─ syncs ──► secret-template.yaml
                  contains: <path:data/vault/Conjur-ArgoCD/secret4#password>
                  └─ AVP sidecar resolves via Conjur JWT auth
                       └─ Conjur authenticator sidecar writes token to shared volume
                            └─ Conjur Cloud returns secret value
                  output ──► Kubernetes Secret "argocd-deployed-secrets"
                                └─ demo pod reads env vars SECRET4, SECRET5
```

**Key components:**

| Component | Image | Role |
|---|---|---|
| `argocd-vault-plugin` sidecar | `itdistrict/argocd-vault-plugin` | AVP binary with Conjur backend support |
| `cyberark-conjur-authn` sidecar | `cyberark/conjur-authn-k8s-client` | Obtains Conjur JWT token, writes to shared volume |
| Demo app | `ghcr.io/assafjh/push-to-k8s-secrets` | Reads `SECRET4`, `SECRET5` from env |

> **Note:** The official `ghcr.io/argoproj-labs/argocd-vault-plugin` image does not include a Conjur backend. `itdistrict/argocd-vault-plugin` is a community image that adds this support.

## Prerequisites

- CyberArk Conjur Cloud tenant
- CyberArk Privilege Cloud (for secret onboarding via Ansible)
- Kubernetes cluster with `kubectl` configured
- `conjur` CLI authenticated to your tenant
- `ansible` + `community.general` collection (see `ansible/01-install-dependencies.sh`)
- Privilege Cloud service account credentials (`CLIENT_ID`, `CLIENT_SECRET`)

## Setup

### 1. Load Conjur policies

Load the four policy files in order from the `policies/` folder:

```
policies/01-base.yml             → creates the argocd branch
policies/02-define-argocd-branch.yml → defines host identity and secrets
policies/03-add-permissions.yml  → grants AVP access to secrets
policies/04-define-jwt-auth.yml  → configures authn-jwt/k8s-argocd1
```

### 2. Get the Conjur public certificate

```bash
export CONJUR_HOST="<your-tenant>.secretsmgr.cyberark.cloud"
./scripts/00-get-conjur-public-cert.sh
# Saves certificate to conjur.crt
```

Then paste the contents of `conjur.crt` into `server-patch/vault-plugin-cm.yml`, replacing the `$CONJUR_PUBLIC_CERTIFICATE` placeholder:

```yaml
AVP_CONJUR_SSL_CERT: |-
  -----BEGIN CERTIFICATE-----
  <paste certificate here>
  -----END CERTIFICATE-----
```

Also update the tenant URL placeholders (`<tenant>`) in `vault-plugin-cm.yml`.

### 3. Enable and configure the JWT authenticator

```bash
./scripts/01-enable-authenticator.sh
./scripts/02-populate-variables.sh
```

### 4. Onboard secrets to Privilege Cloud

```bash
cd ansible
./01-install-dependencies.sh

export CLIENT_ID="<your-service-account-id>"
export CLIENT_SECRET="<your-service-account-secret>"
./02-run-book.sh
```

Creates safe `Conjur-ArgoCD` with secrets `secret1`–`secret8` (random passwords).

### 5. Deploy ArgoCD

```bash
./scripts/03-deploy-argocd.sh
```

Installs ArgoCD into the `argocd` namespace and waits for it to be ready.

### 6. Patch ArgoCD with the AVP sidecar

```bash
./scripts/04-patch-argocd-server.sh
```

Applies the kustomization in `server-patch/`, which:
- Adds the AVP sidecar and Conjur authenticator sidecar to `argocd-repo-server`
- Sets the ArgoCD admin password
- Exposes the ArgoCD server as a LoadBalancer on port 8082

### 7. Deploy the demo application

```bash
kubectl apply -f demo-app/application.yaml
```

ArgoCD syncs the application. AVP replaces the `<path:...>` placeholders in `secret-template.yaml` with live values from Conjur and creates the Kubernetes Secret `argocd-deployed-secrets` in the `conjur-argocd` namespace.

## Expected outcome

- ArgoCD UI shows the application as `Synced / Healthy`
- `kubectl get secret argocd-deployed-secrets -n conjur-argocd` exists and contains `secret4` and `secret5`
- The demo pod has `SECRET4` and `SECRET5` populated from Conjur Cloud

## Folder structure

```
argocd/
├── ansible/          # Privilege Cloud safe + secret onboarding
├── demo-app/         # ArgoCD Application, secret template, demo deployment
├── policies/         # Conjur policy files (load in order)
├── scripts/          # Setup scripts 00–04 (run in order)
└── server-patch/     # Kustomize config — patches argocd-repo-server
```
