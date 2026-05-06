# Pre-Publication TODO

> Last updated: 2026-05-06 — reconciled against git history post-sanitize pass.
>
> Owner decisions (unchanged):
> - Sanitize HEAD only — no git history rewrite.
> - All tenants/identifiers are personal demo systems — no real customers.
> - GHCR free tier — lean and efficient over feature-rich.
> - No removing folders unless byte-level duplicates.
> - Conjur policy logic untouched.

---

## Completed (documented for reference)

- Root README, LICENSE, SECURITY.md present
- `node_modules/` and `*.log` removed from tracking + `.gitignore`
- Per-folder READMEs expanded: ansible, jenkins, terraform, teamcity, circleci, aws-iam, dynamic-privileged-access
- `kubernetes-jwt` manifest templating refactored (envsubst → Kustomize 6902)
- Docker images migrated to GHCR: jenkins, postgres-companydb, push-to-file, push-to-k8s-secrets, rest-api-app (merged from rest-api-app-jwt + rest-api-app-authenticator-client), secretless, summon — OCI labels on all
- `images/spring-boot-zoo/` retired and removed
- `images/rest-api-app-jwt/` and `images/rest-api-app-authenticator-client/` deduplicated → single `images/rest-api-app/`
- **Sanitize pass** (`bab013e`): springboot-sdk API key, Cognito secrets, SIA MFA token, DPA postgres password + hostname, internal hostnames in kubernetes-jwt-priv-cloud, Bruno/Postman collections, SCA-GCP.md, safe-onboarding.yml files, aws-iam python script, credential-provider/bruno — all replaced with placeholders
- `springboot-sdk/compiled/` JARs and `.properties` files removed from tracking
- `intro-demo/webapp/.env` → `.env.example`; `.gitignore` updated
- `dynamic-privileged-access/rds-postgres-ephemeral-access.sh` renamed (typo fixed), README created
- `.gitignore` fixed: `.claude/` dir, build artifacts, `.env` pattern with `!*.env.example` negation
- `CLAUDE..md` untracked
- `jwt-demo/` removed (byte-identical duplicate of `intro-demo`)
- Root README revised and expanded (multiple passes through `6420fbc`)
- Spring Boot hot-reload rewrite: `code/springboot-hot-reload/` — new module with `SecretFileWatcher`, `@RefreshScope` DataSource, Testcontainers integration test, multi-stage Dockerfile, CI workflow (`4fead42`, `41b74f8`)
- Policies `README.md` + PNG diagrams removed from all demo `policies/` subfolders — 14 READMEs, 13 PNGs (`d4db373`)
- Image retention policy added to CI

---

## Phase 1 — Remaining security items

### TASK-108: Final HEAD-only secret scan
**Priority:** BLOCKER · **Category:** Security · **Effort:** S

**Context:** The sanitize pass (`bab013e`) covered targeted files. This is the defense-in-depth sweep confirming HEAD is clean before publishing. Several `.env` files are still tracked (see list below) — verify each is intentional (example files with placeholders) or untrack.

**Tracked `.env` files to verify (not `.env.example`):**
- `aws-iam/elastic/python/.env`
- `custom-certificates/conjur/.env`
- `custom-certificates/tools/.env`
- `images/postgres-companydb/.env`
- `images/postgres-companydb/tools/.env`
- `python-conjur-sdk/.env`
- `terraform/scripts/.env`

**Action:**
1. Open each `.env` above — if it contains real values, sanitize or rename to `.env.example`; if it's already placeholder-only, leave it and note here.
2. `gitleaks detect --source . --no-git` (HEAD only).
3. `trufflehog filesystem .` for entropy-based detection.
4. `grep -rE "[A-Za-z0-9+/=]{40,}" --include="*.{sh,yml,yaml,json,properties,env,py}" .` — manual review of any remaining base64-shaped strings.
5. Resolve every finding.

**Acceptance:**
- [ ] All tracked `.env` files contain only placeholders or are renamed to `.env.example`.
- [ ] `gitleaks` and `trufflehog` exit clean on HEAD.

---

## Phase 2 — Image / build cleanup

### TASK-203: Verify and update Summon binary versions
**Priority:** MEDIUM · **Category:** Code · **Effort:** S
**File:** [images/summon/Dockerfile](images/summon/Dockerfile)

**Context:** Dockerfile downloads `summon` and `summon-conjur` from GitHub releases. Versions were pinned years ago — check if they've been updated in the sanitize pass or are still stale.

**Action:**
1. Check current latest releases of `cyberark/summon` and `cyberark/summon-conjur` on GitHub.
2. If versions in the Dockerfile differ, update URLs + rebuild.
3. Optionally: add SHA256 checksum verification to the curl-tar pipeline.

**Acceptance:**
- [ ] Summon binaries are at current upstream versions.

---

### TASK-204b: Re-route ZooServlet to companydb
**Priority:** MEDIUM · **Category:** Code · **Effort:** S
**Files:**
- [application-server-credential-provider/code/demo-app/src/main/java/com/example/ZooServlet.java](application-server-credential-provider/code/demo-app/src/main/java/com/example/ZooServlet.java)
- [application-server-credential-provider/code/demo-app/src/test/java/com/example/ZooTest.java](application-server-credential-provider/code/demo-app/src/test/java/com/example/ZooTest.java)
- [application-server-credential-provider/code/demo-app/src/main/webapp/index.jsp](application-server-credential-provider/code/demo-app/src/main/webapp/index.jsp)
- [application-server-credential-provider/scripts/03-deploy-postgres-server.sh](application-server-credential-provider/scripts/03-deploy-postgres-server.sh)
- [application-server-credential-provider/scripts/04-configure-datasource.sh](application-server-credential-provider/scripts/04-configure-datasource.sh)

**Context:** Servlet still queries the `zoo` schema. `companydb` is now the canonical demo database. Servlet code itself is well-structured — only the SQL and column references need updating; no rewrite.

**Action:**
1. Replace `SELECT * FROM zoo` with companydb equivalent (verify schema in [images/postgres-companydb/demo-db.sql](images/postgres-companydb/demo-db.sql)).
2. Update column references in ZooServlet.java and table headers in HTML output.
3. Update ZooTest.java queries.
4. Update postgres deployment scripts to use companydb.
5. Optional rename: `ZooServlet` → `CustomerServlet`, `/zoo` → `/customers`.
6. Apply multi-stage Maven build — drop committed WAR.

**Acceptance:**
- [ ] No `zoo`/`vet` references in `application-server-credential-provider/`.
- [ ] WAR is built by CI, not committed.
- [ ] Side-by-side `CyberArkDS` vs `PostgresDS` comparison still works.

---

### TASK-204c: Reposition ASCP demo README
**Priority:** MEDIUM · **Category:** Docs · **Effort:** S
**Files:** [application-server-credential-provider/README.md](application-server-credential-provider/README.md), [README.md](README.md)

**Context:** "Legacy" framing is imprecise — ASCP is current/supported; it's the *deployment scenario* (traditional Java app servers) that's the legacy story. The ASCP demo + new Spring Boot hot-reload demo form a strong contrast pair if positioned correctly.

**Action:**
1. Open README with the "traditional Java app servers" framing (Tomcat, WebSphere, WebLogic, JBoss).
2. Add "Modern equivalent" callout linking to `code/springboot-hot-reload`.
3. One-line note that the WebLogic Credential Mapper was deprecated 2023 → Driver Proxy is now supported path.
4. Update root README scenario blurb accordingly.

**Acceptance:**
- [ ] README opens with traditional-app-server framing, not "legacy".
- [ ] Cross-link to Spring Boot hot-reload demo present.

---

### TASK-204d: Remove old `code/spring-boot-zoo` and remaining build artifacts
**Priority:** MEDIUM · **Category:** Code · **Effort:** S

**Context:** New hot-reload rewrite lives in `code/springboot-hot-reload/`. The old `code/spring-boot-zoo/` still exists in the repo and contains a tracked Maven wrapper JAR. `credential-provider/compiled/CyberArkCredentialProvider.jar` origin is unknown.

**Tracked artifacts still present:**
- `code/spring-boot-zoo/.mvn/wrapper/maven-wrapper.jar` — Maven wrapper, low risk but old code should go
- `credential-provider/compiled/CyberArkCredentialProvider.jar` — unclear origin
- `credential-provider/compiled/config.properties`

**Action:**
1. Confirm `code/spring-boot-zoo/` is no longer referenced by any manifest or CI workflow.
2. `git rm -r code/spring-boot-zoo/`.
3. For `CyberArkCredentialProvider.jar`: investigate origin — if it's a vendor JAR, document provenance and version in the demo README and keep; if buildable from sources, add multi-stage build and drop the JAR.
4. Verify `compiled/` is covered by `.gitignore`.

**Acceptance:**
- [ ] `code/spring-boot-zoo/` gone.
- [ ] `git ls-files | grep -E '\.(jar|war)$'` returns only Maven wrapper JARs and any documented vendor JARs.
- [ ] Origin of `CyberArkCredentialProvider.jar` documented.

---

### TASK-205: Update all manifest image references to GHCR
**Priority:** HIGH · **Category:** Code · **Effort:** M
**Depends on:** TASK-204b, TASK-204d

**Context:** Many manifests still reference `docker.io/assafhazan/*`. The CI tag strategy was updated (`dc85562`) but manifest files themselves were not swept. Confirmed hits include kubernetes-cert, kubernetes-jwt-priv-cloud, argocd, jenkins manifests.

**Action:**
1. `git grep -lE "(docker\.io/assafhazan|assafhazan/[a-z-]+)"` — list every file.
2. For each, replace with `ghcr.io/assafjh/<image>:<tag>`.
3. Document which demos need runtime verification before publishing.

**Acceptance:**
- [ ] `git grep "assafhazan"` returns nothing outside of TODO.md and commit messages.

---

### TASK-206: CI quality gates
**Priority:** MEDIUM · **Category:** Code · **Effort:** M

**Context:** Image build CI exists and works. Missing: linting and secret scanning on every push.

**Action:**
1. Add `shellcheck` workflow over all `.sh`.
2. Add `yamllint` (relaxed) over all `.yml`/`.yaml`.
3. Add `gitleaks` on every push (HEAD-only).
4. Surface as PR checks.

**Acceptance:**
- [ ] PR checks cover shell/yaml lint + secret scan.

---

## Phase 3 — Documentation

### TASK-301: Write READMEs for undocumented demo folders
**Priority:** HIGH · **Category:** Docs · **Effort:** L
**Files:** Per-folder READMEs + [README.md](README.md)

**Context:** These folders have no top-level README or are missing from the root README scenarios list:
- `argocd`
- `code` (what does this top-level folder contain post-cleanup?)
- `databricks`
- `kubernetes-jwt-priv-cloud` (clarify distinction from `kubernetes-jwt`)
- `python-conjur-sdk`
- `secure-ai-access`
- `secure-cloud-access`
- `springboot-sdk`
- `intro-demo` (rich demo, deserves feature-quality README)

**Action:**
1. Write per-folder README: purpose, prerequisites, setup, run commands, expected outcome.
2. Add each to root README "Scenarios" list with one-line description.
3. For variants (`kubernetes-jwt-priv-cloud` vs `kubernetes-jwt`), state the difference at the top.

**Acceptance:**
- [ ] Every top-level folder appears in root README or is explicitly archived.
- [ ] Every kept demo folder has a README.

---

### TASK-303: Strengthen root README portfolio framing
**Priority:** MEDIUM · **Category:** Docs · **Effort:** S
**File:** [README.md](README.md)
**Depends on:** TASK-301

**Context:** README has been improved across several passes but still needs a "Featured demos" section and a "How to read this repo" orientation block for recruiters.

**Action:**
1. Add "Featured demos" section — 3 picks with one-line "what this demonstrates" each (see open question Q2).
2. Add "How to read this repo" block explaining `policies/` / `scripts/` / `manifests/` / `images/` layout.
3. Verify "About me" section links to LinkedIn / portfolio site.

**Acceptance:**
- [ ] README answers "what / who / why / where to start" in the first screen.

---

## Phase 4 — Per-demo polish

> Run after Phase 2 image migration so manifests are touched only once.

- [x] `.circleci`
- [x] `.github`
- [x] `deploy-conjur`
- [x] `kubernetes-jwt`
- [x] `ansible-awx-tower`
- [x] `ansible`
- [x] `application-server-credential-provider` *(pending TASK-204b/c)*
- [ ] `kubernetes-cert`
- [ ] `jenkins`
- [ ] `github-actions`
- [ ] `circleci`
- [ ] `aws-iam`
- [ ] `terraform`
- [ ] `gitlab-ci`
- [ ] `rest-api`
- [ ] `azure-devops`
- [ ] `kubernetes-follower`
- [ ] `custom-certificates`
- [ ] `kubernetes-external-secrets-operator`
- [ ] `kubernetes-jwt-priv-cloud`
- [ ] `upgrade-conjur-enterprise-version`
- [ ] `teamcity`
- [ ] `credential-provider`
- [ ] `central-credential-provider`
- [ ] `argocd`
- [ ] `springboot-sdk`
- [ ] `secure-ai-access`
- [ ] `secure-cloud-access`
- [ ] `dynamic-privileged-access`
- [ ] `python-conjur-sdk`
- [ ] `intro-demo`
- [ ] `databricks`
- [ ] `code/springboot-hot-reload` *(new — verify post-rewrite)*

### Per-folder review protocol

**FIX directly:** typos, missing `set -euo pipefail`, unquoted variables, broken paths, grammar.
**FLAG and ask:** anything that changes behavior or requires a design decision.
**Never silently skip** — fix or flag.

**Conjur policy `.yml`:** logic untouched. Descriptive variable names, comment polish only.
**Shell `.sh`:** `set -euo pipefail`, `conjur whoami` before Conjur ops, quoted variables.
**Kubernetes `.yml`:** consistent namespace/SA/labels, ConfigMap-driven Conjur connection details.
**README:** policy paths match folder structure, variable names match policies, no absolute GitHub image URLs.

---

## Phase 5 — Efficiency review

### TASK-501: Shell script efficiency sweep
**Priority:** MEDIUM · **Category:** Code · **Effort:** L

**Context:** Beyond bash hygiene: batching, idempotency, curl retry/timeout, polling vs sleep.

**Action:** Per demo, list inefficiencies, FIX where local, FLAG when design call. Add `shellcheck` to CI (TASK-206).

---

### TASK-502: Manifest hardening sweep
**Priority:** MEDIUM · **Category:** Code · **Effort:** L

**Context:** Resource `requests`/`limits`, `imagePullPolicy`, `securityContext`, liveness/readiness probes — inconsistent across demos.

**Action:** Per manifest folder, add resource limits, set pull policy, add probes/securityContext where they don't break the demo.

---

### TASK-503: Dockerfile efficiency on migrated images
**Priority:** LOW · **Category:** Code · **Effort:** S

**Context:** `--no-cache` missing on some `apk add`; `USER` directive missing; `postgres-companydb` has hardcoded `POSTGRES_PASSWORD="123456"`.

**Action:**
1. Add `--no-cache` to all `apk add`.
2. Add `USER 1000:1000` where entrypoint allows.
3. Decide on postgres-companydb password handling (document or force env var).

---

## Phase 6 — Portfolio polish

### TASK-601: Architecture diagrams (Mermaid) for featured demos
**Priority:** LOW · **Category:** Docs · **Effort:** L
**Depends on:** featured-demos decision (open question Q2)

**Action:** For each featured demo, add a Mermaid system-flow diagram showing trust boundary, who calls whom, where the secret enters/leaves. Inline in README so it renders on GitHub.

---

### TASK-602: Demo navigator script
**Priority:** NICE-TO-HAVE · **Category:** Portfolio · **Effort:** S
**Depends on:** TASK-301, TASK-303 (READMEs must be complete first — agent uses them as input)

**Context:** ~40-60 line Python script at repo root. User describes their stack/pain point; script calls Claude API and returns the most relevant demo with a one-line reason. Strong portfolio signal for the agentic AI SME angle — but only works if per-demo READMEs are complete and clear.

**Action:**
1. Write `recommend-demo.py` using the Anthropic SDK.
2. Feed it the root README scenario list as context.
3. Accept free-text input; return: demo name, path, one-sentence reason.
4. Add to root README under "Not sure where to start?"

---

## Final review

### TASK-701: Clean-clone walkthrough before going public
**Priority:** BLOCKER · **Category:** Final review · **Effort:** M
**Depends on:** Phase 1 + Phase 2 done; Phase 3 substantially done

**Action:**
1. `git clone <local> /tmp/cybr-demos-test && cd /tmp/cybr-demos-test`
2. Read root README cold — note every confusion or broken link.
3. Pick one featured demo; run from README only.
4. Run `gitleaks detect` and `trufflehog filesystem .` on HEAD.
5. Confirm `ghcr.io/assafjh/*` images are reachable anonymously.

**Acceptance:**
- [ ] Stranger walkthrough produces zero blockers.
- [ ] Scanners clean.
- [ ] Owner comfortable telling a recruiter "skim this repo."

---

## Open questions

1. **Portfolio email** — `assafjh@gmail.com` or a dedicated portfolio address for the About section?
2. **Featured demos** — which 3 to highlight? Suggestion: `kubernetes-jwt` (breadth), `code/springboot-hot-reload` (depth/hot-reload story), `secure-ai-access` (differentiated). Owner picks.
3. **GHCR tag strategy** — semver / git SHA / `latest`? Recommend pinned semver in manifests + moving `:latest` for human pulls.
4. **`credential-provider/compiled/CyberArkCredentialProvider.jar`** — vendor JAR or buildable? Determines whether it stays (documented) or gets a multi-stage build.

---

## Out of scope / explicitly decided against

- **Git history scrub.** 4 years of personal history > scrub benefit. HEAD sanitized; history accepted as-is.
- **Customer-name concerns.** All identifiers are personal demo systems.
- **Removing folders.** Every orphan gets documented. Only byte-identical duplicates removed.
- **Rewriting demo logic.** Hygiene, sanitization, docs, efficiency only — never behavior.
- **Adding new demos.** Polish what exists before publication.
- **Restructuring under a single CLI/Makefile.** Per-demo numbered-script convention is intentional.
- **Secrets Auditor agent.** Strong product idea — tracked separately in `SECRETS_AUDITOR_PRODUCT_IDEA.md`; spin into its own repo after this one ships.
