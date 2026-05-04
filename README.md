# CYBR-Demos

[![Images CI Status](https://github.com/assafjh/cybr-demos/actions/workflows/images.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/images.yml)
[![Ansible Package Status](https://github.com/assafjh/cybr-demos/actions/workflows/ansible-aws-demo.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/ansible-aws-demo.yml)
[![ASCP Package Status](https://github.com/assafjh/cybr-demos/actions/workflows/ascp-demo.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/ascp-demo.yml)

Hands-on demos and reference implementations for CyberArk Identity Security use cases.

This repository contains self-contained scenarios used in real-world POCs, integrations, and customer environments across cloud, DevOps, and traditional infrastructure.

Each folder represents a standalone demo with its own instructions, prerequisites, and execution flow.

Created and maintained by [Assaf Hazan](https://www.linkedin.com/in/assafjh)
(Presales Architect, CyberArk / Palo Alto Networks)

---

## 📂 Repository Structure

Most demo folders follow a consistent structure:

* `policies/` – Conjur RBAC policies (YAML)
* `scripts/` – Step-by-step execution scripts (e.g., `01-install.sh`, `02-run.sh`)
* `manifests/` – Kubernetes, Terraform, or Ansible configurations
* `code/` / `images/` – Demo application code and Dockerfiles

---

## 🧭 Choosing a Demo

There is no single entry point — each demo is independent.

Pick a scenario based on your use case:

* **General flow / end-to-end example** → `intro-demo`
* **Local Conjur setup** → `deploy-conjur`
* **Kubernetes integrations** → `kubernetes-*`
* **CI/CD pipelines** → `jenkins`, `github-actions`, `gitlab-ci`, `azure-devops`
* **Infrastructure as Code** → `terraform`, `ansible`, `argocd`
* **Traditional apps / servers** → `credential-provider`, `central-credential-provider`
* **Cloud & advanced use cases** → `aws-iam`, `secure-cloud-access`, `secure-ai-access`

Each demo includes its own instructions.

---

## 🛠️ Technologies Covered

* **CyberArk Platform**: Conjur, Privilege Cloud (PCloud), Credential Providers (CP/CCP), Secure Cloud Access (SCA), Secure Access (SIA), Secure AI Agents
* **CI/CD**: Jenkins, GitHub Actions, GitLab CI, CircleCI, TeamCity, Azure DevOps
* **Infrastructure**: Kubernetes, OpenShift, Terraform, Ansible, AWS
* **Languages**: Java, Node.js, Python, Bash

---

## 🚀 Scenarios & Demonstrations

### Getting Started & Core

* `deploy-conjur` – Local Conjur deployment
* `intro-demo` – End-to-end demo (web app, Lambda, Ansible)
* `rest-api` – Conjur REST API examples
* `upgrade-conjur-enterprise-version` – Version upgrade flow

### ☁️ Cloud Native & Kubernetes

* `kubernetes-jwt`
* `kubernetes-jwt-priv-cloud`
* `kubernetes-cert`
* `kubernetes-follower`
* `kubernetes-external-secrets-operator`

### 🔄 CI/CD Pipeline Security

* `jenkins`
* `github-actions`
* `gitlab-ci`
* `circleci`
* `azure-devops`
* `teamcity`

### 🏗️ Infrastructure as Code (IaC) & GitOps

* `ansible`
* `ansible-awx-tower`
* `terraform`
* `argocd`

### 🏢 Traditional Infrastructure & Application Servers

* `credential-provider`
* `central-credential-provider`
* `application-server-credential-provider`

### 💻 Developer Tools & SDKs

* `springboot-sdk`
* `python-conjur-sdk`

### 🌩️ Cloud, AI & Advanced Integrations

* `aws-iam`
* `databricks`
* `secure-cloud-access`
* `secure-ai-access`
* `dynamic-privileged-access`
* `custom-certificates`

---

## ⚠️ Disclaimer

This repository is an unofficial project created for demo and POC purposes by a Palo Alto Networks employee.

It is not an official product and is not endorsed or supported by CyberArk or Palo Alto Networks.

All environments referenced are lab environments with no customer data.
Content is provided "as-is" and should be reviewed before any production use.
