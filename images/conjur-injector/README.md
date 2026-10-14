# conjur-injector
Mutating admission webhook that wires annotated pods to Conjur with JWT authentication. `conjur.org/inject-type`:
- `secrets-provider` (default) - adds the Secrets Provider; placement and destination come from the provider's own `conjur.org/container-mode` and `conjur.org/secrets-destination` (file or k8s_secrets)
- `summon` - copies static summon binaries in with an init container and wraps the app command (env vars, no image change)

- Go standard library only - no client-go, single static binary on distroless.
- Unit tests run as part of the Docker build.
- Never denies a pod: invalid annotations → admitted un-injected with an admission warning.

Used by the [kubernetes-mutating-webhook](../../kubernetes-mutating-webhook) demo.

## Configuration (environment)
| Variable | Required | Default |
|---|---|---|
| `CONJUR_APPLIANCE_URL` | yes | |
| `CONJUR_AUTHN_URL` | yes | |
| `CONJUR_ACCOUNT` | | `conjur` |
| `CONJUR_AUTHENTICATOR_ID` | | derived from the last segment of `CONJUR_AUTHN_URL` |
| `CONJUR_SSL_CERTIFICATE` | | (PEM) |
| `CONJUR_IDENTITY_PATH` | | `data/kubernetes/applications` |
| `PROVIDER_IMAGE` | | `cyberark/secrets-provider-for-k8s:latest` |
| `PROVIDER_IMAGE_PULL_POLICY` | | `IfNotPresent` |
| `PROVIDER_RUN_AS_USER` | | `777` (0 = unset, for OpenShift) |
| `SUMMON_IMAGE` | | `ghcr.io/assafjh/conjur-summon-bin:latest` |
| `SUMMON_IMAGE_PULL_POLICY` | | `IfNotPresent` |
| `JWT_AUDIENCE` | | (none) |
| `JWT_EXPIRATION_SECONDS` | | `3600` |
| `TLS_CERT_FILE` / `TLS_KEY_FILE` | | `/etc/webhook/certs/tls.crt` / `tls.key` |
| `LISTEN_ADDR` | | `:8443` |

## Local test
```bash
go test ./...
```
