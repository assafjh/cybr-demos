# Domain-Based Dynamic Secret Retrieval — Ansible + Secrets Manager (Conjur Cloud)

Ansible retrieves credentials from CyberArk Secrets Manager SaaS dynamically,
resolved per **domain** (derived from each host's FQDN) — no secrets stored in
the playbook or inventory. Retrieval only; connecting to targets is out of scope.

## How it works
FQDN → domain (`split`) → `data/ansible/domains/<domain>/{username,password}` → runtime lookup.
A host in a different domain resolves a different credential with no playbook change.

## Layout
- `policies/`  — Conjur policy: base branch + per-domain credential branches + consumer host
- `scripts/`   — run in order: bootstrap → load-policy → set-secrets → runbook
- `playbook/`  — the retrieval playbook, inventory, ansible.cfg

## Run order
1. `scripts/01-bootstrap.sh`   — install collection + `conjur whoami` sanity check
2. `scripts/02-load-policy.sh` — load policies (capture the host API key shown once)
3. `scripts/03-set-secrets.sh` — inject credential values
4. cp `.env.example` → `.env`, fill in tenant URL + API key
5. `scripts/04-runbook.sh`     — run the playbook

## Prerequisites
- ansible-core 2.17+, `cyberark.conjur` collection
- A Secrets Manager SaaS tenant; outbound 443

## Notes
- The domain in each FQDN must match the branch id in the policy.
- Validation prints presence only (`no_log` + length check) — secret values are never logged.