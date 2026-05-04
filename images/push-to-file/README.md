# Conjur Push-to-File Demo Application

This repository contains a lightweight, Alpine-based container designed specifically to demonstrate the **CyberArk Conjur Secrets Provider (Push-to-File)** pattern. 

It acts as a "dummy" application that halts its initialization process and waits for an external Sidecar/Init-Container to inject secrets into a shared volume before proceeding.

## 🏗️ Architectural Design

*   **Zero-Knowledge Start:** The application starts with absolutely no credentials or secrets baked into the image.
*   **Dependency Checking:** It actively monitors a predefined file path (`/opt/secrets/conjur/`) for the presence of specific secret files (`credentials.yaml` and `credentials.properties`).
*   **Time-Bound Wait:** Implements a configurable timeout to prevent infinite hanging if the Secrets Provider fails to deliver the secrets.
*   **Multi-Architecture:** Built and tested for `linux/amd64` and `linux/arm64`.

## 📁 Repository Structure

*   `Dockerfile` - Optimized Alpine image utilizing `dumb-init` for proper signal handling.
*   `scripts/entry-point.sh` - The core logic that loops, waits, and eventually consumes the injected secrets.

## ⚙️ Configuration (Environment Variables)

The behavior of the container can be customized via the following environment variables:

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `INJECTED_FILES_PATH` | `/opt/secrets/conjur` | The directory path where the container expects the Sidecar to write the secrets. |
| `WAIT_TIMEOUT` | `5` | Maximum time (in seconds) to wait for secrets before failing and exiting. |
| `RUN_MESSENGER` | `false` | If `true`, attempts to execute an external `messenger` binary located in the injected path after secrets are found. |

## 🚀 Deployment (Simulation)

To test the container's behavior locally without a full Kubernetes/Conjur environment, you can simulate the sidecar injection using Docker volumes or `docker exec`:
```bash
# 1. Start the application container (it will begin waiting)
docker run -d --name push-to-file-app ghcr.io/assafjh/push-to-file:latest

# 2. Simulate the Conjur Sidecar injecting the files
docker exec push-to-file-app sh -c "mkdir -p /opt/secrets/conjur && echo 'db_pass: Secret123' > /opt/secrets/conjur/credentials.yaml"
docker exec push-to-file-app sh -c "echo 'db_pass=Secret123' > /opt/secrets/conjur/credentials.properties"

# 3. Check the logs to verify successful consumption
docker logs push-to-file-app
```

## ✅ Continuous Integration (CI) Testing

The automated CI pipeline includes a robust **Smoke Test** that verifies the container's logic:
1.  **Negative Test:** Ensures the container correctly crashes (Exit Code 1) if secrets are not injected within the `WAIT_TIMEOUT`.
2.  **Positive Test:** Simulates injection and verifies that the container detects the files, logs them, and stays alive (`sleep infinity`).
