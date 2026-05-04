# Summon Demo App

A simple Alpine-based image that demonstrates injecting secrets into an application process using **CyberArk Summon** and the `summon-conjur` provider.

The application itself (`demo-consumer.sh`) contains **no credentials** and does not know how to communicate with CyberArk. Summon acts as a wrapper: it authenticates to Conjur, fetches the required secrets, and injects them securely into the application's memory as environment variables.

## Image Location

This image is automatically built and published to the GitHub Container Registry (GHCR):

`docker pull ghcr.io/assafjh/summon:latest`

## Configuration (`secrets.yml`)

Summon relies on a `secrets.yml` file to map Conjur variable paths to local environment variable names. 
By default, the image includes a sample file requesting `SECRET2` and `SECRET4`. 

In a real Kubernetes deployment, you should override this file by mounting a `ConfigMap` containing your own `secrets.yml` to `/scripts/secrets.yml`.

## Usage

The image's `ENTRYPOINT` is natively wrapped with Summon. When the container starts, it automatically attempts to fetch the secrets and execute `/scripts/demo-consumer.sh`, outputting the injected variables to the logs.

During a live demo, you can interactively execute the script through Summon by running:

```bash
kubectl exec -it <pod-name> -c <app-container> -- summon -p summon-conjur -f /scripts/secrets.yml /scripts/demo-consumer.sh
```