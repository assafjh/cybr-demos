# 🐯 CyberArk ASCP Demo: Jakarta Servlet on Tomcat
[![ASCP Build Status](https://github.com/assafjh/cybr-demos/actions/workflows/ascp-demo.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/ascp-demo.yml)

### Secure Secrets Management with Zero Code Changes

This repository demonstrates the integration of **CyberArk Application Server Credential Provider (ASCP)** with a modern **Jakarta EE** application running on **Apache Tomcat 10+**. It showcases how to eliminate hardcoded credentials and static configuration files by leveraging JNDI-based secret retrieval.

---

## 🎯 The Core Value: Zero Code Changes
The primary goal of this demo is to prove that moving to a vault-less architecture does not require refactoring your application code:
*   **The Application**: Requests a `DataSource` via standard JNDI lookup.
*   **The Server (Tomcat)**: Configured with a CyberArk JDBC Proxy/Factory.
*   **The Result**: Credentials are intercepted and injected by the CyberArk Agent at runtime, keeping them out of your source code and configuration files.

---

## 🏗️ Architecture Overview
The demo environment consists of:
*   **Application**: A Jakarta Servlet (`CustomerServlet.java`) querying a PostgreSQL database.
*   **Frontend**: A modern Dashboard (`index.jsp`) to compare standard vs. managed connections.
*   **Infrastructure**: 
    *   **Apache Tomcat 10+**: Supporting Jakarta EE and Java 17.
    *   **PostgreSQL 17**: Running in a Docker container (`ghcr.io/assafjh/postgres-companydb`). Note: ASCP officially certifies PostgreSQL 11.x; the JDBC driver is compatible with newer versions in practice, but this is outside the supported matrix.
    *   **CyberArk ASCP Agent**: Providing the secure bridge to the Vault.
*   **CI/CD**: GitHub Actions pipeline for automated builds and releases.

---

## 🚀 Quick Deployment

### Prerequisites
*   A Linux environment (RHEL/CentOS recommended).
*   Docker/Podman for the database.
*   CyberArk Credential Provider installer (`.tar.gz`) placed in the `scripts/` folder.

### Step-by-Step Guide
Follow the numbered scripts in order:
1.  **`./01-install-agent.sh`**: Installs the CyberArk CP Agent.
2.  **`./02-install-tomcat.sh`**: Downloads and extracts Tomcat 10+.
3.  **`./03-deploy-postgres-server.sh`**: Provisions the demo database.
4.  **`./04-configure-datasource.sh`**: Injects JNDI resources into Tomcat's `context.xml`.
5.  **`./05-pull-app.sh`**: Pulls the latest build from GitHub Releases or uses a local build.
6.  **`./06-start-tomcat.sh`**: Boots the server.

---

## 📦 Latest Build & Artifacts
The application is automatically built and packaged using GitHub Actions.
*   **Latest WAR File**: Download the most recent stable build from our [Releases Page](https://github.com/assafjh/cybr-demos/releases/tag/ascp-demo-latest-build).
*   **Automated Pull**: Script `05-pull-app.sh` is pre-configured to fetch this artifact directly.

---

## 🧪 Testing the Demo
1.  Open your browser at `http://localhost:8081/demo-app`.
2.  **Standard Connection**: Connects using a static password in `context.xml`.
3.  **CyberArk Managed Connection**: Connects using the ASCP Driver. Observe that the password in `context.xml` is a dummy value, yet the connection succeeds!

---

## 🛠️ Local Development
If you need to make changes to the code during a demo:
*   **Compile Locally**: Use `./optional-compile-demo.sh` to rebuild the WAR file using Maven and Java 17.
*   **Re-deploy**: Run `./05-pull-app.sh` to update the application in Tomcat.

---

## 🔒 Security Note
This demo implements CWE-209 protection by sanitizing database error messages. Never print full stack traces or real secrets in production logs.
