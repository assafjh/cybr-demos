# REST API App — Unified Demo Image

A single image that demonstrates two ways a pod can retrieve a secret from Conjur via the REST API. The authentication mode is selected at **runtime** via the `AUTH_MODE` environment variable — no need to build separate images.

## Authentication Modes

| `AUTH_MODE` | REST calls | How it works |
|---|---|---|
| `pre-authenticated` *(default)* | **1** (GET secret) | Reads a Conjur access-token from `/run/conjur/access-token`, injected by the **Conjur authenticator-client** sidecar/init container. The sidecar handles authentication — this can be **certificate-based** (`authn-k8s`) or **JWT-based** (`authn-jwt`), transparent to the app. |
| `self-authenticated` | **2** (POST authenticate + GET secret) | Reads the pod's K8s service-account JWT and authenticates **directly** to Conjur via `authn-jwt`. No sidecar needed — the app handles the full auth flow itself. |

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `AUTH_MODE` | ❌ | `pre-authenticated` (default) or `self-authenticated` |
| `CONJUR_APPLIANCE_URL` | ✅ | Conjur appliance URL, e.g. `https://<tenant>.secretsmgr.cyberark.cloud/api` |
| `CONJUR_ACCOUNT` | ✅ | Conjur account name, e.g. `conjur` |
| `CONJUR_VARIABLE_PATH` | ✅ | Path of the variable to retrieve, e.g. `data/kubernetes/applications/safe/secret1` |
| `CONJUR_AUTHN_URL` | `self-authenticated` only | Conjur authn-jwt URL, e.g. `https://<tenant>.secretsmgr.cyberark.cloud/api/authn-jwt/k8s-cluster1` |

## Usage

### Pre-authenticated mode (with sidecar)

Deploy with a `conjur-authn-k8s-client` sidecar that writes the access token. No `AUTH_MODE` override needed (it defaults to `pre-authenticated`).

### Self-authenticated mode (no sidecar)

Set `AUTH_MODE=self-authenticated` in the pod spec:

```yaml
env:
  - name: AUTH_MODE
    value: "self-authenticated"
```
