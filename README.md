# CYBR-Demos

[![Images CI Status](https://github.com/assafjh/cybr-demos/actions/workflows/images.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/images.yml)
[![Ansible Package Status](https://github.com/assafjh/cybr-demos/actions/workflows/ansible-aws-demo.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/ansible-aws-demo.yml)
[![ASCP Package Status](https://github.com/assafjh/cybr-demos/actions/workflows/ascp-demo.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/ascp-demo.yml)

Hands-on, end-to-end demos and reference implementations for CyberArk Identity Security use cases.

This repository contains real-world POC scenarios across cloud-native platforms, CI/CD pipelines, and traditional infrastructure. Each folder represents a standalone, end-to-end integration flow with its own instructions, prerequisites, and architectural details.

Created and maintained by [Assaf Hazan](https://www.linkedin.com/in/assafjh)  
*(Senior Presales Architect | Machine Identity & DevSecOps, Palo Alto Networks)*

---

## 📂 Repository Structure

Most demo folders follow a consistent structure for predictability:

* `policies/` – Conjur RBAC policies (YAML) defining hosts, variables, and entitlements
* `scripts/` – Numbered bash scripts (e.g., `01-install.sh`, `02-run.sh`) to execute the demo steps in order
* `manifests/` – Kubernetes YAML files or Terraform/Ansible configurations
* `code/` & `images/` – Source code for the demo applications and multi-stage Dockerfiles (published to GHCR)

---

## 🧭 Choosing a Demo

There is no single entry point — each demo is independent and represents a full end-to-end scenario.

Pick a scenario based on your use case:

* **Core integration / app secret retrieval** → `intro-demo`
* **Local Conjur setup** → `deploy-conjur`
* **Kubernetes integrations** → `kubernetes-*`
* **CI/CD pipelines** → `jenkins`, `github-actions`, `gitlab-ci`, `azure-devops`, `circleci`, `teamcity`
* **Infrastructure as Code** → `terraform`, `ansible`, `ansible-awx-tower`, `argocd`
* **Traditional apps / servers** → `credential-provider`, `central-credential-provider`, `application-server-credential-provider` (Tomcat, WebLogic, WebSphere, IIS)
* **Cloud & advanced use cases** → `aws-iam`, `secure-cloud-access`, `secure-ai-access`, `dynamic-privileged-access`

Each demo includes its own instructions and execution flow.

---

## 🛠️ Technologies Covered

* **CyberArk Platform:** Conjur, Privilege Cloud (PCloud), Credential Providers (CP/CCP), Application Server Credential Provider (ASCP), Secure Cloud Access (SCA), Secure Access (SIA), Secure AI Agents
* **CI/CD:** Jenkins, GitHub Actions, GitLab CI, CircleCI, TeamCity, Azure DevOps
* **Infrastructure:** Kubernetes, OpenShift, Terraform, Ansible, AWS (EC2, Lambda)
* **Languages & Frameworks:** Java (Spring Boot, Tomcat), Node.js, Python, Shell scripting

---

## 🚀 Scenarios & Demonstrations

**Getting Started & Core**
* `deploy-conjur`: Scripts to quickly deploy a local Conjur environment
* `intro-demo`: Core Conjur integration demonstrating standard application secret retrieval
* `rest-api`: REST API call examples for Conjur
* `upgrade-conjur-enterprise-version`: Upgrade a demo Conjur Enterprise server version

**☁️ Cloud Native & Kubernetes**
* `kubernetes-jwt`: Integration with Kubernetes using the JWT Authenticator
* `kubernetes-jwt-priv-cloud`: Kubernetes JWT authentication tailored for private cloud environments
* `kubernetes-cert`: Integration with Kubernetes using the Certificate Authenticator
* `kubernetes-follower`: Conjur Enterprise follower deployment inside Kubernetes clusters
* `kubernetes-external-secrets-operator`: Using Kubernetes ESO with the Conjur provider

**🔄 CI/CD Pipeline Security**
* `jenkins`: Integration with Jenkins using the Conjur plugin (JWT and Default authenticators)
* `github-actions`: Integration with GitHub Actions using the CyberArk Conjur Secret Fetcher
* `gitlab-ci`: Integration with GitLab CI using JWT authentication via REST and Summon
* `circleci`: Integration with CircleCI using JWT authentication
* `azure-devops`: Integration with Azure DevOps using Azure IMDS OAuth2
* `teamcity`: Conjur integration with TeamCity

**🏗️ Infrastructure as Code (IaC) & GitOps**
* `ansible`: Secure dynamic secret retrieval with Ansible
* `ansible-awx-tower`: Integration with Ansible AWX/Tower
* `terraform`: Integration with HashiCorp Terraform
* `argocd`: GitOps secrets management integration with ArgoCD

**🏢 Traditional Infrastructure & Application Servers**
* `credential-provider`: CP agent deployed on Linux and Plain Old Java app demo
* `central-credential-provider`: CCP demo (REST, SOAP)
* `application-server-credential-provider`: Integration pattern for traditional application servers (Tomcat, WebLogic, WebSphere, IIS) using JDBC Driver Proxy

**💻 Developer Tools & SDKs**
* `springboot-sdk`: Spring Boot integration using the Conjur SDK
* `python-conjur-sdk`: Utilities and demos for the Python Conjur SDK

**🌩️ Cloud, AI & Advanced Integrations**
* `aws-iam`: Passwordless authentication for AWS Lambda and EC2 using IAM roles
* `databricks`: Databricks integration with Conjur
* `secure-cloud-access`: Secure Cloud Access (SCA) demo for zero-standing privileges
* `secure-ai-access`: Secure AI Access (SIA) demo for securing AI agents and LLM interactions
* `dynamic-privileged-access`: RDS Postgres ephemeral access via DPA
* `custom-certificates`: Using Conjur Enterprise with 3rd-party certificates

---

## ⚠️ Disclaimer

This repository is an unofficial project created for demonstration and POC purposes by a CyberArk / Palo Alto Networks employee.

It is not an official product and is not endorsed or supported by CyberArk or Palo Alto Networks.

All environments referenced are isolated lab tenants containing no customer data. Scripts and configurations are provided "as-is" and should be reviewed before any production use.
