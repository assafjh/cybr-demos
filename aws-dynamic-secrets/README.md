# AWS Dynamic Secrets with Conjur Cloud

Demonstrates Conjur Cloud's dynamic secrets capability for AWS: instead of storing static IAM credentials, Conjur generates short-lived STS credentials on demand via AssumeRole. Credentials expire automatically (default 15 minutes) and are never persisted.

## How it works

```
App calls Conjur  ──►  Conjur calls AWS STS AssumeRole
                              │
                              └──► Returns: AccessKeyId + SecretAccessKey + SessionToken (TTL: 900s)
                              │
                   ◄──  Conjur returns temporary credentials to app
```

Conjur holds one set of long-lived IAM user keys (the "issuer"). Every secret retrieval generates fresh STS credentials scoped to a specific IAM role — no static credentials distributed to applications.

## Prerequisites

- AWS CLI configured with permissions to create IAM users, roles, and policies
- Conjur Cloud tenant with a `data/dynamic` policy branch
- `conjur` CLI authenticated (`conjur whoami`)
- `jq`

To override the Conjur CLI path:
```bash
export CONJUR_CLI=/path/to/conjur
```

## Setup

### 1. Create AWS resources and Conjur issuer

```bash
./01-create-issuer.sh create-all-resources
```

Creates:
- IAM user `dynamic-demo-secrets-ec2-user` with an EC2 policy (describe/start/stop)
- IAM role `dynamic-demo-secrets-ec2-role` with a trust policy scoped to that user
- Access keys for the user
- Conjur issuer `aws-demo-issuer` backed by those access keys

To run these steps separately:
```bash
./01-create-issuer.sh create-aws-resources   # AWS only
./01-create-issuer.sh create-conjur-issuer   # Conjur issuer only (requires AWS resources)
```

### 2. Create the Conjur dynamic variable

```bash
./02-demo.sh setup-conjur-policy
```

Loads a variable into `data/dynamic` with annotations that tell Conjur to use `aws-demo-issuer`, assume the EC2 role, and generate STS credentials on retrieval.

## Demo

Retrieve dynamic credentials and print them:
```bash
./02-demo.sh demo-dynamic-secret
```

Retrieve credentials and immediately use them to query EC2:
```bash
./02-demo.sh demo-ec2-access
```

Expected output includes the temporary `AccessKeyId`, `SecretAccessKey`, and `SessionToken`, followed by a live EC2 instance list from `eu-west-2`.

## Cleanup

```bash
./01-create-issuer.sh delete-aws-resources
```

Detaches policies, deletes access keys, removes the IAM role and user. The Conjur issuer and policy variable must be removed manually via the Conjur CLI or UI.

## Configuration

All resource names are defined at the top of each script:

| Variable | Default | Description |
|---|---|---|
| `AWS_POLICY_NAME` | `dynamic-demo-secrets-ec2-policy` | IAM policy name |
| `AWS_ROLE_NAME` | `dynamic-demo-secrets-ec2-role` | IAM role name |
| `AWS_USER_NAME` | `dynamic-demo-secrets-ec2-user` | IAM user name |
| `AWS_REGION` | `eu-west-2` | AWS region for EC2 queries |
| `ISSUER` | `aws-demo-issuer` | Conjur issuer ID |
| `MAX_TTL` | `900` | Credential TTL in seconds |
