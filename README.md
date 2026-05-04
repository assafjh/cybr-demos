# CYBR-Demos
[![Images CI Status](https://github.com/assafjh/cybr-demos/actions/workflows/images.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/images.yml) [![Ansible Package Status](https://github.com/assafjh/cybr-demos/actions/workflows/ansible-aws-demo.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/ansible-aws-demo.yml) [![ASCP Package Status](https://github.com/assafjh/cybr-demos/actions/workflows/ascp-demo.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/ascp-demo.yml)

This repository contains a collection of reference architectures, integration patterns, and proof-of-concept demonstrations for CyberArk Identity Security solutions. It provides technical, hands-on examples of securing DevOps pipelines, cloud-native environments, and traditional infrastructure.

This repository bridges the gap between security policies and developer workflows. It demonstrates how to achieve Zero Trust and eliminate hardcoded secrets across modern and legacy toolchains without slowing down R&D.

Created and maintained by [Assaf Hazan](https://www.linkedin.com/in/assafjh).

Instructions, prerequisites, and architectural details for each specific scenario can be found documented within its respective folder.

## 📂 How to Read This Repo
Most demo folders follow a standard structure for predictability:
* `policies/`: Conjur RBAC policies (YAML) defining hosts, variables, and entitlements.
* `scripts/`: Numbered bash scripts (e.g., `01-install.sh`, `02-run.sh`) to execute the demo steps in order.
* `manifests/`: Kubernetes YAML files or Terraform/Ansible configurations.
* `code/` & `images/`: Source code for the demo applications and multi-stage Dockerfiles (published to GHCR).

## 🛠️ Technologies Used
- **CyberArk Platform**: Privilege Cloud (PCloud), Conjur, Credential Providers (CP/CCP), Secure Cloud Access (SCA), Secure Access (SIA), Secure AI Agents
- **CI/CD**: Jenkins, GitHub Actions, GitLab CI, CircleCI, TeamCity, Azure DevOps
- **Orchestration & Infrastructure**: Kubernetes (K8s), OpenShift (OCP), Terraform, Ansible, AWS (EC2, Lambda)
- **Languages & Frameworks**: Java (Spring Boot, Tomcat), Node.js, Shell Scripting, Python

---

## ⚠️ Disclaimer
This is a personal repository containing demonstrations and proof-of-concept integrations. It is **not** officially affiliated with, endorsed by, or supported by CyberArk. All environments are isolated, personal lab tenants containing no real customer data or contractual risk. Scripts and configurations are provided "as-is" for educational purposes.

---

## 🚀 Scenarios & Demonstrations

**Getting Started & Core**
* `deploy-conjur`: Scripts to quickly deploy a local Conjur environment.
* `intro-demo`: Comprehensive introduction to Conjur (Webapp, Lambda, Ansible).
* `rest-api`: REST API call examples for Conjur.
* `upgrade-conjur-enterprise-version`: Upgrade a demo Conjur Enterprise server version.

**☁️ Cloud Native & Kubernetes**
* `kubernetes-jwt`: Integration with Kubernetes using the JWT Authenticator.
* `kubernetes-jwt-priv-cloud`: Kubernetes JWT authentication tailored for private cloud environments.
* `kubernetes-cert`: Integration with Kubernetes using the Certificate Authenticator.
* `kubernetes-follower`: Conjur Enterprise follower deployment inside Kubernetes clusters.
* `kubernetes-external-secrets-operator`: Using Kubernetes ESO with the Conjur provider.

**🔄 CI/CD Pipeline Security**
* `jenkins`: Integration with Jenkins using the Conjur plugin (JWT and Default authenticators).
* `github-actions`: Integration with GitHub Actions using the CyberArk Conjur Secret Fetcher.
* `gitlab-ci`: Integration with GitLab CI using JWT authentication via REST and Summon.
* `circleci`: Integration with CircleCI using JWT authentication.
* `azure-devops`: Integration with Azure DevOps using Azure IMDS OAuth2.
* `teamcity`: Conjur Integration with TeamCity.

**🏗️ Infrastructure as Code (IaC) & GitOps**
* `ansible`: Secure dynamic secret retrieval with Ansible.
* `ansible-awx-tower`: Integration with Ansible AWX/Tower.
* `terraform`: Integration with HashiCorp Terraform.
* `argocd`: GitOps secrets management integration with ArgoCD.

**🏢 Traditional Infrastructure & Application Servers**
* `credential-provider`: CP agent deployed on Linux and Plain Old Java app demo.
* `central-credential-provider`: CCP demo (REST, SOAP).
* `application-server-credential-provider`: Integration pattern for **traditional Java application servers** (Tomcat, WebLogic, WebSphere) using JDBC Driver Proxy.

**💻 Developer Tools & SDKs**
* `springboot-sdk`: Spring Boot integration using the Conjur SDK.
* `python-conjur-sdk`: Utilities and demos for the Python Conjur SDK.

**🌩️ Cloud, AI & Advanced SaaS Integrations**
* `aws-iam`: Passwordless authentication for AWS Lambda and EC2 using IAM roles.
* `databricks`: Databricks integration with Conjur.
* `secure-cloud-access`: Secure Cloud Access (SCA) demo for zero-standing privileges.
* `secure-ai-access`: Secure AI Access demo for securing AI agents and LLM interactions.
* `dynamic-privileged-access`: RDS Postgres ephemeral access via SIA.
* `custom-certificates`: Using Conjur Enterprise with 3rd-party certificates.