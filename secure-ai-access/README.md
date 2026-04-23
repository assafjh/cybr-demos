```markdown
# Secure Infrastructure Access (SIA) - PostgreSQL ZSP Lab

This project demonstrates how to provide Zero Standing Privileges (ZSP) access to a PostgreSQL database running on Docker in AWS EC2, managed by CyberArk Secure Infrastructure Access (SIA).

## Project Structure
```text
# Secure Infrastructure Access (SIA) - PostgreSQL ZSP Lab

[cite_start]This project demonstrates how to provide Zero Standing Privileges (ZSP) access to a PostgreSQL database running on Docker in AWS EC2, managed by CyberArk Secure Infrastructure Access (SIA)[cite: 2, 3].

## Project Structure
```text
.
├── database
│   ├── 01-test-connectivity-to-postgres.sh  # Basic connectivity check
│   └── 02-test-connectivity-with-sia.sh     # SIA ZSP Read-Only test script
└── terraform
    ├── postgres.tf                          # EC2 (ARM) + Docker + Elastic IP
    ├── sia-connector.tf                     # SIA Connector EC2 instance
    ├── outputs.tf                           # Infrastructure outputs (FQDN, IPs)
    ├── providers.tf                         # AWS Provider configuration
    ├── variables.tf                         # Infrastructure variables
    └── terraform.tfvars                     # Environment-specific values
```

## Phase 1: Infrastructure Deployment (Terraform)

### Key Architectural Decisions:
1. **Architecture**: Used `t4g.small` (AWS Graviton/ARM64) for cost-efficiency.
2. **Persistence**: Assigned an **Elastic IP** to the PostgreSQL instance to ensure the Public IP remains static.
3. **Connectivity (FQDN)**: SIA requires a Fully Qualified Domain Name (FQDN) for stable resource identification. We use the AWS **Public DNS** associated with the Elastic IP (e.g., `ec2-xx-xx-xx-xx.compute.amazonaws.com`).
4. **Containerization**: PostgreSQL 17 is deployed via Docker. The image `assafhazan/postgres-companydb:17-alpine` is pre-configured with a sample database (`companydb`).

### Deployment Steps:
1. Navigate to the `terraform` directory.
2. Run `terraform init` and `terraform apply`.
3. Note the `postgres_fqdn` from the outputs. This is your target address for SIA.

## Phase 2: Database Preparation (Strong Account)

SIA requires a **Strong Account** to provision ephemeral users. 
In this lab, the custom Docker image (`assafhazan/postgres-companydb:17-alpine`) comes pre-configured with a strong administrative user:
- **Username**: `admin`
- **Password**: `123456`

Because this user is already configured with high privileges (including `CREATEROLE` and `CONNECT`), **no manual database configuration or `ALTER` commands are required**. SIA can use this account out-of-the-box to provision ephemeral ZSP users.

## Phase 3: CyberArk Vault Configuration (Privilege Cloud)

1. **Safe Setup**:
   - Add the role `Secure Infrastructure Privilege Cloud Ephemeral Access` as a Safe Member.
   - Set the permissions for this role to **Read only**.
2. **Account Onboarding**:
   - Onboard the Strong Account (`admin` / `123456`) to the Safe.
   - Use the **PostgreSQL Platforms**.
   - **Critical**: Use the **Elastic IP FQDN** in the Address field.
   - Use **Customize account name** and give it a unique name (e.g., `PostgreSQL-CompanyDB-Admin`).

## Phase 4: SIA Configuration

### 1. Link Strong Account
- Go to **Strong accounts** -> **DATABASES**.
- Add a new account: **Vaulted in Privilege Cloud**.
- Provide the exact **Safe** and **Account name** from the Vault.

### 2. Database Onboarding
- Go to **Resource management** -> **Databases** -> **Onboard**.
- Type: **PostgreSQL**.
- Address: Enter the **Public FQDN** from Terraform.
- Authentication: **Ephemeral local user**.
- Strong Account: Select the account linked in the previous step.

### 3. Connector Pool
- Edit your Connector Pool.
- In the **FQDNs** section, add the target FQDN using the **Exactly** operator to ensure precise routing (alternatively, use a wildcard like `*.eu-west-2.compute.amazonaws.com`).

### 4. Access Policy
- Create a **Recurring access policy** for Databases.
- Add your PostgreSQL resource as an Asset.
- **Access Rule Profile**: Use the built-in PostgreSQL role **`pg_read_all_data`**. This ensures users have "Read-Only" access without needing to manually create roles.
- Add your Identity users/groups as Members.

## Phase 5: Testing and Validation

### MFA Caching
To avoid constant MFA prompts, use **MFA Caching**:
1. Open the **Secure Access space** in the CyberArk portal.
2. Select the PostgreSQL target and go to the **Token** tab.
3. Generate and copy the **MFA Cache Token**.

### Read-Only Validation
Run the provided test script:
```bash
./database/02-test-connectivity-with-sia.sh
```
The script will:
1. Authenticate using the MFA Cache Token (as `PGPASSWORD`).
2. Identify your ephemeral identity and assigned roles.
3. Successfully run `SELECT` queries.
4. **Fail** on `CREATE`, `INSERT`, or `DROP` commands, proving the `pg_read_all_data` restriction.

## References
- CyberArk SIA Documentation: Introduction to Secure Infrastructure Access
- Supported Databases: PostgreSQL 14 and later is supported.
- ZSP Flow: SIA generates a unique ephemeral local user for every authorized connection.
```