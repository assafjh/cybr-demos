# 🐯 CyberArk ASCP Demo: Jakarta Servlet on Tomcat
### Secure Secrets Management with Zero Code Changes

This repository demonstrates the integration of **CyberArk Application Server Credential Provider (ASCP)** with a modern **Jakarta EE** application running on **Apache Tomcat**. It showcases how to eliminate hardcoded credentials and static configuration files by leveraging JNDI-based secret retrieval.

---

## 🎯 The Core Value: Zero Code Changes
The primary goal of this demo is to prove that moving to a vault-less architecture does not require refactoring your application code. 
*   **The Application:** Requests a `DataSource` via standard JNDI lookup[cite: 2].
*   **The Server (Tomcat):** Configured with a CyberArk JDBC Proxy/Factory[cite: 1].
*   **The Result:** Credentials are intercepted and injected by the CyberArk Agent at runtime, keeping them out of your source code and configuration files[cite: 1, 2].

---

## 🏗️ Architecture Overview
The demo environment consists of:
*   **Application:** A Jakarta Servlet (`ZooServlet.java`) that queries a PostgreSQL database[cite: 1, 2].
*   **Frontend:** A clean, modern Dashboard (`index.jsp`) to compare standard vs. managed connections[cite: 3].
*   **Infrastructure:** 
    *   **Apache Tomcat 10+** (supporting Jakarta EE)[cite: 1, 2].
    *   **PostgreSQL 11** running in a Docker container[cite: 1].
    *   **CyberArk ASCP Agent** providing the secure bridge to the Vault[cite: 1].
*   **CI/CD:** GitHub Actions pipeline for automated builds and testing[cite: 1].

---

## 📂 Project Structure
*   `code/demo-app/`: Maven-based Java source code[cite: 1].
*   `scripts/`: A series of numbered Bash scripts to provision the entire environment from scratch[cite: 1].
*   `bruno/`: Modern API collection for automated onboarding and testing[cite: 1].
*   `.github/workflows/`: Automated build and test pipeline.

---

## 🚀 Getting Started

### Prerequisites
*   A Linux environment (RHEL/CentOS recommended).
*   Docker/Podman for the database[cite: 1].
*   CyberArk Credential Provider installer (`.tar.gz`) placed in the `scripts/` folder[cite: 1].

### Step-by-Step Deployment
Follow the numbered scripts in order:
1.  **`./01-install-agent.sh`**: Installs the CyberArk CP Agent[cite: 1].
2.  **`./02-install-tomcat.sh`**: Downloads and extracts Tomcat 10+[cite: 1].
3.  **`./03-deploy-postgres-server.sh`**: Provisions the demo database[cite: 1].
4.  **`./04-configure-datasource.sh`**: Injects JNDI resources into Tomcat's `context.xml`[cite: 1].
5.  **`./05-deploy-app.sh`**: Pulls the latest build from GitHub or builds locally and deploys to Tomcat[cite: 1].
6.  **`./06-start-tomcat.sh`**: Boots the server[cite: 1].

---

## 🧪 Testing the Demo
1.  Open your browser at `http://localhost:8081/demo-app`[cite: 1].
2.  **Standard Link:** Connects using a static password in `context.xml` (Classic/Insecure method)[cite: 3].
3.  **CyberArk Link:** Connects using the ASCP Driver. Observe that the password in `context.xml` is a dummy value, yet the connection succeeds![cite: 2, 3]

---

## 🛠️ Development & CI/CD
*   **Maven Build:** Run `mvn clean package` to generate the `.war` file[cite: 1].
*   **Automated Pipeline:** Every push to this repo triggers a **GitHub Action** that builds the application and uploads the artifact[cite: 1].
*   **Security:** This demo implements CWE-209 protection by sanitizing database error messages[cite: 2].
