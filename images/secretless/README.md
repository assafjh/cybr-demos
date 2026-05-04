# Secretless Broker Demo App

A simple Alpine-based PostgreSQL client image used to demonstrate **CyberArk's Secretless Broker**. 

The application itself contains **no credentials**. It connects to a local port (`localhost:5432` by default), where the Secretless Broker sidecar intercepts the connection, fetches the real credentials from Conjur, and securely proxies the traffic to the target PostgreSQL database.

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `DB_HOST` | `localhost` | Target database host (typically `localhost` when using Secretless sidecar). |
| `DB_PORT` | `5432` | Target database port (the port Secretless listens on). |
| `DB_NAME` | `companydb` | The name of the database to query. |
| `TABLE_NAME` | `customers` | The table name to fetch records from during the demo. |

## Usage

When the container starts, `/scripts/entry-point.sh` executes a basic connection test displaying the current user and the contents of the target table, and then the container "sleeps" (`sleep infinity`) to stay alive.

During a live demo, you can interactively execute queries through the Secretless Broker by running:

```bash
kubectl exec -it <pod-name> -c <app-container> -- /scripts/query-database.sh
```