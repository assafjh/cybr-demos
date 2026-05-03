# Jenkins JCasC Demo Environment

[![Build Status](https://github.com/assafjh/cybr-demos/actions/workflows/build-jenkins-image.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/build-jenkins-image.yml)

This repository provides a custom Jenkins Docker image tailored for demonstrating dynamic secrets management and Identity integrations. It utilizes **Jenkins Configuration as Code (JCasC)** to spin up a fully configured, secure, and ready-to-use controller with zero manual UI setup.

## 📁 Repository Contents

*   `Dockerfile` - Assembles the image and sets up the base environment.
*   `plugins.txt` - Explicit list of pre-installed plugins required for the demo.
*   `casc.yml` - The JCasC manifest that provisions roles, security realms, and global configurations.
*   `run_jenkins.sh` - A ready-to-use deployment script to inject runtime variables.

## ⚙️ How It Works

The image is designed to be ephemeral and dynamic. Instead of hardcoding values, the `casc.yml` relies on environment variables injected at runtime. This allows you to connect the Jenkins controller to any environment instantly.

## 🚀 Quick Start

You can run the environment using the provided bash script, which dynamically passes your parameters into the container. 

Simply configure your variables and execute:

```bash
# Define your environment parameters
export JENKINS_ADMIN_ID="admin"
export JENKINS_ADMIN_PASSWORD="" # <-- Insert your desired password here
export JENKINS_ADDRESS=$(hostname -f)
export JENKINS_PORT=8080
export CONJUR_FQDN="$(hostname -f):443"
export CONJUR_ACCOUNT="conjur"

# Run the pre-configured image
docker run -d \
  --name jenkins \
  --restart=always \
  -p "$JENKINS_PORT":8080 \
  -e JENKINS_ADMIN_ID \
  -e JENKINS_ADMIN_PASSWORD \
  -e JENKINS_ADDRESS \
  -e JENKINS_PORT \
  -e CONJUR_FQDN \
  -e CONJUR_ACCOUNT \
  docker.io/assafhazan/jenkins:conjur
```

*(Note: Adjust the image registry URL to your active GitHub/Docker registry as needed).*
