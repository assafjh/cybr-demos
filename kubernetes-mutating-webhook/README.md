# Kubernetes auto-onboarding with a mutating admission webhook
Demo for zero-touch wiring of Kubernetes workloads to Conjur: a mutating admission webhook (**conjur-injector**) that adds the Conjur plumbing to pods at creation time.

The app team writes a plain Deployment and declares **which** secrets it needs and **how** it consumes them. The Secrets Provider or Summon, volumes, JWT token, Conjur URL, account, authenticator and CA certificate are all added by the platform.

> **Positioning.** Everything shown relies on built-in product capabilities - Secrets Provider for Kubernetes, Summon, the JWT authenticator and policy as code. The injector itself is a standard Kubernetes pattern implemented on top of them: a **reference implementation, not a supported CyberArk component**. CyberArk also publishes an official [sidecar-injector](https://github.com/cyberark/sidecar-injector) for the Kubernetes (authn-k8s) authenticator; this demo shows the same pattern with authn-jwt.

## Consumption types
| `inject-type` | Configured with | App sees | Image change | Rotation |
|---|---|---|---|---|
| `secrets-provider` (default) | provider's own `secrets-destination: file` + `container-mode: sidecar` (defaults) or `init` | files in an in-memory volume | none | live (sidecar) |
| `secrets-provider` | provider's own `secrets-destination: k8s_secrets` + `container-mode: init` (default) or `sidecar` | a regular K8s Secret (`secretKeyRef` / `envFrom`) | none | sidecar updates the Secret |
| `summon` | `summon-secrets` | environment variables | **none** - summon is injected, not baked in | on restart |

For the Secrets Provider the injector introduces no new vocabulary: anyone who knows the provider's annotations already knows how to configure it.

`summon` is the one to highlight: until now Summon meant rebuilding every app image and changing CI. Here the injector copies static summon binaries into the pod and wraps the command - the image is untouched.

## How it works
```
kubectl apply ──► API server ──► MutatingWebhookConfiguration (namespace label conjur.org/injection=enabled)
                                          │ AdmissionReview (pod)
                                          ▼
                                  conjur-injector ── conjur.org/inject: "true"?  inject-type?
                                          │ JSON patch
          ┌───────────────────────────────┼─────────────────────────────────┐
  provider, destination file      provider, destination k8s_secrets      summon
 + provider (sidecar|init)      + provider (init|sidecar)       + init container copying summon
 + in-memory secrets volume     (writes to an existing Secret)    + summon-conjur to /conjur/bin
 + read-only mount in app                                         + secrets.yml projected from the
                                                                    pod's own annotation
                                                                  + app command wrapped with summon
          └──────────────── + projected SA token (JWT) + conjur.org/inject-identity ───────────────┘
                                          ▼
                Pod authenticates with authn-jwt as host/<branch>/system:serviceaccount:<ns>:<sa>
```
- Scope (`INJECT_SCOPE` in the deploy script):
  - `labeled` (default) - only namespaces labeled `conjur.org/injection=enabled` are sent to the webhook.
  - `all` - every namespace except `kube-*` and the injector's own. For demo environments: the pod annotation is the only opt-in, so you just annotate any workload anywhere.
- Either way, pods without `conjur.org/inject: "true"` are never changed.
- The webhook never blocks a pod over bad annotations - it admits it un-injected with a warning (`kubectl` shows it).
- `FAILURE_POLICY` - `Fail` (default for `labeled`): pods in scope are not created while the injector is down. `Ignore` (default for `all`): they start un-injected - a down injector must never stop the whole cluster.
- Injected containers carry a Pod Security `restricted` securityContext (non-root, no privilege escalation, all capabilities dropped, RuntimeDefault seccomp), so they are admitted in any namespace. The app's own containers are not touched.
- The injector holds no Conjur credentials and no Kubernetes API permissions.
- Conjur connection details live in one place: the injector's ConfigMap (copied from the kubernetes-jwt `conjur-connect` by the deploy script). App namespaces need none.

## Pod annotations
| Annotation | Applies to | Default | Meaning |
|---|---|---|---|
| `conjur.org/inject` | all | - | `"true"` to inject |
| `conjur.org/inject-type` | all | `secrets-provider` | `secrets-provider` or `summon` |
| `conjur.org/inject-mount-path` | provider, destination file | `/conjur/secrets` | where app containers see the secret files |
| `conjur.org/inject-containers` | provider (file), summon | all containers | comma-separated app containers to inject into |
| `conjur.org/summon-secrets` | summon | - | `secrets.yml` content (env var → `!var path`) |
| `conjur.org/summon-command` | summon | - | the original command, when the manifest has no `command` (JSON array or plain string) |

Plus the standard Secrets Provider annotations. The injector **reads** `conjur.org/container-mode` (`sidecar`/`init`) and `conjur.org/secrets-destination` (`file`/`k8s_secrets`) to decide placement, writing back only the defaults it filled in; everything else (`conjur-secrets.*`, `secret-file-path.*`, templates, refresh, `k8s-secrets`) is passed through untouched to the provider.

Written by the injector: `conjur.org/inject-status: injected` and `conjur.org/inject-identity` - the Conjur host id the pod authenticates as.

### Type notes
- **k8s_secrets** - the webhook cannot create objects (`sideEffects: None`), so the target Secret (with its `conjur-map`) and a Role letting the pod's SA `get`/`update` it must exist. `manifests/03-demo-apps.yml` includes both, scoped to the one Secret.
- **summon** - the injector needs the app's original command. It uses `command` from the manifest if present (args are kept), otherwise `conjur.org/summon-command`. It cannot read the image ENTRYPOINT; without either, the pod is admitted un-injected with a warning. Secrets are read when the process starts - restart to pick up a new value.

## Prerequisites
- The [kubernetes-jwt](../kubernetes-jwt) demo up to and including `manifests/01-create-infra.yml`: policies loaded, `k8s-cluster1` JWT authenticator enabled and populated, `conjur-connect` ConfigMap in `conjur-jwt`.
- kubectl/oc with cluster-admin (the webhook configuration is cluster-scoped), `openssl`, the Conjur CLI.
- Images, built by `.github/workflows/images.yml`:
  - `ghcr.io/assafjh/conjur-injector` from [images/conjur-injector](../images/conjur-injector)
  - `ghcr.io/assafjh/conjur-summon-bin` from [images/conjur-summon-bin](../images/conjur-summon-bin) (linux/amd64)
  - For a private registry, override `INJECTOR_IMAGE`, `SUMMON_IMAGE`, `PROVIDER_IMAGE` (and `INJECTOR_PULL_POLICY`) when running the deploy script.

## Instructions
### 1. Load the demo host
The injector wires pods to Conjur; it does not create Conjur identities. Each injected ServiceAccount needs a host.
```bash
conjur login -i kubernetes-admin01
conjur policy update -b data/kubernetes -f policies/01-define-webhook-demo-hosts.yml | tee -a 01-define-webhook-demo-hosts.log
conjur logout
```
### 2. Preflight the Conjur side
Checks the authenticator permit, the host and its group, and that every demo variable has a value - and prints the exact fix for anything missing. Run as admin.
```bash
scripts/00-preflight.sh
```
If it reports the group cannot authenticate:
```bash
conjur policy update -b conjur/authn-jwt/k8s-cluster1 -f policies/02-permit-authenticator.yml
```
### 3. Deploy the injector
Generates the webhook CA and serving certificate, deploys the injector with the connection ConfigMap and registers the webhook. Safe to re-run (rotates the certificate).
```bash
scripts/01-deploy-injector.sh                      # labeled namespaces only
INJECT_SCOPE=all scripts/01-deploy-injector.sh     # demo environment: any namespace, annotation is the opt-in
```
Other knobs: `INJECTOR_IMAGE`, `SUMMON_IMAGE`, `PROVIDER_IMAGE`, `INJECTOR_PULL_POLICY`, `FAILURE_POLICY`, and `PROVIDER_RUN_AS_USER` (the Secrets Provider image runs as a named user, so kubelet needs a numeric uid to verify non-root: `777` by default, automatically `0` on OpenShift where the SCC assigns the uid - no OpenShift-specific step needed).
### 4. Deploy the demo apps
Open `manifests/03-demo-apps.yml` first and show there is no Conjur plumbing in it.
```bash
scripts/02-deploy-demo-apps.sh
```
### 5. Show the result
Deployment (what the app team wrote) vs running pod (after the injector), the Conjur identity and the app log. Pass app names to show only some.
```bash
scripts/03-show-injection.sh
scripts/03-show-injection.sh demo-summon
kubectl logs -n conjur-injector deploy/conjur-injector -f      # injector decisions live
```
Live rotation with the file sidecar:
```bash
conjur variable set -i data/kubernetes/applications/safe/secret3 -v "rotated-$RANDOM"
kubectl exec -n conjur-webhook-demo deploy/demo-file-sidecar -c demo-application -- cat /opt/secrets/conjur/credentials.yaml
```
### 6. Onboard your own workload
With `INJECT_SCOPE=labeled`, label the namespace first (with `all`, skip this):
```bash
kubectl label namespace <namespace> conjur.org/injection=enabled
```
Add `conjur.org/inject: "true"` and the Secrets Provider annotations (or `inject-type: summon` with `summon-secrets`) to the pod template, then add a host named after the `conjur.org/inject-identity` annotation to Conjur.
### 7. Cleanup
```bash
scripts/99-cleanup.sh
```

## Troubleshooting
- **Pod created without injection** - `kubectl get events -n <ns>` shows the webhook warning; the injector log says why (namespace not labeled, missing annotation, no command for summon...).
- **Pod not created at all** - injector unreachable with a fail-closed webhook: `kubectl get pods -n conjur-injector`.
- **403 / CONJ00006E "does not have 'authenticate' privilege"** - the host's group has no `authenticate` on the authenticator. Run `scripts/00-preflight.sh`.
- **401** - the host in `conjur.org/inject-identity` does not exist.
- **404 on a variable** - the variable exists but has no value; the provider fails the whole batch. Run `scripts/00-preflight.sh`.
- **k8s_secrets: `forbidden` updating the Secret** - the Role/RoleBinding is missing or names a different Secret.
- **`CreateContainerConfigError: image has non-numeric user ... cannot verify user is non-root`** - `PROVIDER_RUN_AS_USER` ended up `0` on a non-OpenShift cluster; re-run with `PROVIDER_RUN_AS_USER=777`.

## Roadmap
- Discovery: scan a cluster for workloads consuming K8s Secrets.
- Onboarding: move a workload's K8s Secrets into Conjur and annotate it in one step.
- Policy as code through CI (host + grant via pull request).
- summon: read the image ENTRYPOINT from the registry when the manifest has no command.
- Helm chart for the injector.
