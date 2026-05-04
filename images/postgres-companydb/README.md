# Hardened PostgreSQL (mTLS Enabled)

This repository provides a hardened PostgreSQL 17 (Alpine-based) image engineered for **Security-in-Transit**. It enforces Mutual TLS (mTLS) by default, ensuring that all database connections are encrypted and authenticated via client certificates.

## 🏗️ Architectural Design

*   **Mutual TLS (mTLS):** Enforced at the engine level. The database will not accept non-SSL connections, requiring a trusted Certificate Authority (CA) chain for both server and client.
*   **Immutable Identity:** Certificates are generated and validated during the CI/CD pipeline using a standardized PKI toolset, ensuring a "Plug-and-Play" secure environment for demos.
*   **Multi-Architecture:** Built and tested for `linux/amd64` and `linux/arm64` to support diverse deployment environments (Cloud/Local/M1-M3 Macs).
*   **Least Privilege by Design:** Includes scoped identities to demonstrate Separation of Duties and Machine Identity use cases natively.
*   **Compliance-Ready:** Adheres to OCI (Open Container Initiative) standards for metadata and labeling.

## 👥 Pre-Configured Identities

The initialization script (`demo-db.sql`) automatically provisions the following roles to support diverse IAM and Secrets Management demonstrations:

1.  **`admin` (DBA / Human Access):** The database owner. Used for SIA / Zero Standing Privileges demos requiring native client connections.
2.  **`reporting_service_ro` (Machine Identity):** A dedicated, read-only service account scoped strictly to `SELECT` operations on business tables. Default password: `reporting123`

## 📁 Repository Structure

*   `Dockerfile` - Hardened assembly with optimized permissions (0600) for private keys.
*   `demo-db.sql` - Automated schema initialization, RBAC setup, and seed data.
*   `tools/` - Automated PKI scripts for Root CA creation, CSR generation, and signing.
*   `certs/` - (Generated at build-time) Placeholder for the runtime identity assets.

## 🚀 Deployment

The image is designed to be self-contained for demo portability. Use the following command to instantiate the secure database:
```bash
# Define environment parameters
export POSTGRES_USER="admin"
export POSTGRES_PASSWORD="" # <-- Set your database admin password
export POSTGRES_DB="postgres"

# Run the mTLS-hardened instance
docker run -d \
  --name postgres-mtls \
  --restart=always \
  -p 5432:5432 \
  -e POSTGRES_USER \
  -e POSTGRES_PASSWORD \
  -e POSTGRES_DB \
  ghcr.io/assafjh/postgres-companydb:17-alpine
```

## ✅ Verification

Once the container is running, verify that the database is initialized and TLS is actively enforcing connections over TCP.

**1. Verify Data Initialization:**
```bash
docker exec -it -e PGPASSWORD=$POSTGRES_PASSWORD postgres-mtls psql -U admin -d postgres -c "SELECT count(*) FROM customers;"
```

**2. Verify Active SSL on TCP Connections:**
*Note: We force the connection via `-h 127.0.0.1` to route through the network interface rather than a local Unix socket, forcing the SSL handshake.*
```bash
docker exec -it -e PGPASSWORD=$POSTGRES_PASSWORD postgres-mtls psql -h 127.0.0.1 -U admin -d postgres -t -c "SELECT ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid();"
```
*(Expected output: `t` for True)*

## 🛡️ Machine Identity Note

For **Demo Portability**, certificates are generated during the CI process and embedded within the image. 

In a **Production Architecture**, this image should be treated as "Identity-less." Certificates and private keys should be injected at runtime via a Secret Provider (e.g., CyberArk Conjur) or managed by a Kubernetes `cert-manager` to ensure zero-trust principles and automated rotation.
