# CYBR-Demos
[![Images CI Status](https://github.com/assafjh/cybr-demos/actions/workflows/images.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/images.yml) [![Ansible Package Status](https://github.com/assafjh/cybr-demos/actions/workflows/ansible-aws-demo.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/ansible-aws-demo.yml) [![ASCP Package Status](https://github.com/assafjh/cybr-demos/actions/workflows/ascp-demo.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/ascp-demo.yml)


Hi, I'm Assaf! 👋 Welcome to my personal demos repository.

This repository serves as a portfolio of my work and contains various demonstrations of integrating CyberArk Tools with a wide range of DevOps tools and platforms.
You can connect with me on [LinkedIn](https://www.linkedin.com/in/assafhazan/).

Instructions for each scenario can be found in its respective folder.

## 📂 How to Read This Repo
Most demo folders follow a standard structure for predictability:
* `policies/`: Conjur RBAC policies (YAML) defining hosts, variables, and entitlements.
* `scripts/`: Numbered bash scripts (e.g., `01-install.sh`, `02-run.sh`) to execute the demo steps in order.
* `manifests/`: Kubernetes YAML files or Terraform/Ansible configurations.
* `code/` & `images/`: Source code for the demo applications and multi-stage Dockerfiles (published to GHCR).

## Technologies Used
- **Secrets Management**: CyberArk Conjur
- **CI/CD**: Jenkins, GitHub Actions, GitLab CI, CircleCI, TeamCity, Azure DevOps
- **Orchestration & Infrastructure**: Kubernetes (K8s), OpenShift (OCP), Terraform, Ansible, AWS (EC2, Lambda)
- **Languages & Frameworks**: Java (Spring Boot, Tomcat), Node.js, Shell Scripting, Python

---

## Disclaimer
This is a personal portfolio repository containing demonstrations and proof-of-concept integrations. It is **not** officially affiliated with, endorsed by, or supported by CyberArk. All environments are isolated, personal lab tenants containing no real customer data or contractual risk. Scripts and configurations are provided "as-is" for educational purposes.

---

## Scenarios
1. deploy-conjur: Scripts to quickly deploy a local Conjur environment.
2. kubernetes-jwt: Integration with Kubernetes using the JWT Authenticator.
3. kubernetes-jwt-priv-cloud: Kubernetes JWT authentication tailored for private cloud environments.
4. kubernetes-cert: Integration with Kubernetes using the Certificate Authenticator.
5. kubernetes-follower: Conjur Enterprise follower deployment inside Kubernetes clusters.
6. kubernetes-external-secrets-operator: Using Kubernetes ESO with the Conjur provider.
7. intro-demo: Comprehensive introduction to Conjur (Webapp, Lambda, Ansible).
8. argocd: GitOps secrets management integration with ArgoCD.
9. ansible: Secure dynamic secret retrieval with Ansible.
10. ansible-awx-tower: Integration with Ansible AWX/Tower.
11. terraform: Integration with HashiCorp Terraform.
12. aws-iam: Passwordless authentication for AWS Lambda and EC2 using IAM roles.
13. jenkins: Integration with Jenkins using the Conjur plugin (JWT and Default authenticators).
14. github-actions: Integration with GitHub Actions using the CyberArk Conjur Secret Fetcher.
15. gitlab-ci: Integration with GitLab CI using JWT authentication via REST and Summon.
16. circleci: Integration with CircleCI using JWT authentication.
17. azure-devops: Integration with Azure DevOps using Azure IMDS OAuth2.
18. teamcity: Conjur Integration with TeamCity.
19. springboot-sdk: Spring Boot integration using the Conjur SDK.
20. python-conjur-sdk: Utilities and demos for the Python Conjur SDK.
21. rest-api: REST API call examples for Conjur.
22. databricks: Databricks integration with Conjur.
23. credential-provider: CP agent deployed on Linux and Plain Old Java app demo.
24. central-credential-provider: CCP demo (REST, SOAP).
25. application-server-credential-provider: Integration pattern for **traditional Java application servers** (Tomcat, WebLogic, WebSphere) using JDBC Driver Proxy.
26. secure-cloud-access: Secure Cloud Access (SCA) demo.
27. secure-ai-access: Secure AI Access (SIA) demo.
28. dynamic-privileged-access: RDS Postgres ephemeral access via DPA.
29. custom-certificates: Using Conjur Enterprise with 3rd-party certificates.
30. upgrade-conjur-enterprise-version: Upgrade a demo Conjur Enterprise server version.
