# Spring Boot Hot-Reload with Conjur Secrets Provider

Demonstrates zero-restart database credential rotation using CyberArk Conjur's
[push-to-file](https://docs.cyberark.com/conjur-enterprise/latest/en/content/integrations/k8s-ocp/cjr-k8s-secrets-provider-push-to-file.htm)
sidecar and Spring Cloud's `@RefreshScope`.

## How it works

```
Conjur Vault
    │  rotates credential
    ▼
push-to-file sidecar  ──writes──▶  /etc/conjur/secrets/db-credentials.properties
                                             │
                                    SecretFileWatcher (WatchService)
                                             │ detects ENTRY_MODIFY
                                             ▼
                                    ContextRefresher.refresh()
                                             │
                                    @RefreshScope DataSource  ──rebuilt with new password──▶  PostgreSQL
```

The Spring context is partially refreshed: only `@RefreshScope` beans are destroyed and
recreated. The rest of the application (JPA, repositories, controllers) keeps running.

## Prerequisites

- Java 21+
- Docker / Docker Compose
- Pull access to `ghcr.io/assafjh/postgres-companydb:17-alpine`

## Quick start (Docker Compose)

```bash
# 1. Create the credentials file (simulates what the Conjur sidecar writes)
mkdir local-secrets
cat > local-secrets/db-credentials.properties <<'EOF'
spring.datasource.username=reporting_service_ro
spring.datasource.password=reporting123
EOF

# 2. Start app + database
docker compose up --build

# 3. Verify connectivity
curl http://localhost:8080/api/status
# {"status":"UP","user":"reporting_service_ro","customers":10}
```

## Demonstrating credential rotation

While `docker compose up` is running:

```bash
# 1. Rotate the password in PostgreSQL
docker compose exec db psql -U admin -d postgres \
  -c "ALTER USER reporting_service_ro WITH PASSWORD 'new_password';"

# 2. Update the credentials file (Conjur sidecar does this automatically in K8s)
cat > local-secrets/db-credentials.properties <<'EOF'
spring.datasource.username=reporting_service_ro
spring.datasource.password=new_password
EOF

# 3. Watch the app logs — you will see:
#   Credentials file changed, refreshing context
#   Context refreshed — new credentials active
#   DB connection OK — 10 customers

# 4. Confirm the app reconnected
curl http://localhost:8080/api/status
```

## Endpoints

| Endpoint | Description |
|---|---|
| `GET /api/status` | Connection status, active DB user, customer count |
| `GET /actuator/health` | Spring Boot health (includes DB liveness) |
| `POST /actuator/refresh` | Manually trigger a context refresh |

## Running tests

```bash
mvn test
```

Tests use Testcontainers (Docker required). `HotReloadIntegrationTest` exercises the full
rotation cycle: rotate DB password → update credentials file → refresh → verify reconnection.

## Kubernetes deployment

K8s manifests are not yet included in this directory. The application is designed for
the Conjur Secrets Provider push-to-file pattern: configure the sidecar to emit a
`.properties` file at `/etc/conjur/secrets/db-credentials.properties` with the keys
`spring.datasource.username` and `spring.datasource.password`. The file watcher
handles the rest automatically.
