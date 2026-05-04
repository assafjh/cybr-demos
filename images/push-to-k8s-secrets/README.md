# Conjur Kubernetes Secrets Demo App

This demo application is designed to verify and demonstrate the **CyberArk Conjur Secrets Provider** when running in **Kubernetes Secrets** mode.

It simply inspects and logs its environment variables, making it easy to confirm that Conjur has successfully synchronized secrets into the Pod's environment.

## 🏗️ Architectural Design

*   **Identity-Driven:** Relies on Kubernetes/Conjur integration to receive secrets.
*   **Environment Inspection:** Automatically filters and highlights any environment variable containing the string `SECRET`.
*   **Signal Handling:** Uses `dumb-init` to properly handle lifecycle events in a containerized environment.

## 🚀 Deployment (Quick Test)

You can test the container's output by injecting a dummy secret via the `-e` flag:

```bash
docker run --rm \
  -e DB_SECRET_PASS="CyberArk123" \
  ghcr.io/assafjh/push-to-k8s-secrets:latest
```

## ✅ Verification

The automated CI pipeline validates that the container:
1. Starts correctly.
2. Correctly identifies and logs variables injected into its environment during runtime.
