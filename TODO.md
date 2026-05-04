# Pre-Publication TODO

> Regenerated 2026-05-04 after owner decisions:
> - Sanitize HEAD only — **no git history rewrite** (4 years of personal history > scrub benefit; demo creds in inactive systems).
> - All tenants/identifiers belong to personal demo systems — no real customers, no contractual risk.
> - GHCR free tier — minimize image storage; lean and efficient over feature-rich.
> - No removing folders unless they are byte-level duplicates; missing READMEs get written.
> - Conjur policy logic untouched. Only descriptive variable renames + comment polish.

## Snapshot — completed in prior pass
- Root README, LICENSE, SECURITY.md present
- `node_modules/` and `*.log` removed from tracking + `.gitignore`
- Most absolute GitHub image URLs converted to relative paths
- Per-folder READMEs expanded for: ansible, jenkins, terraform, teamcity, circleci, aws-iam
- `kubernetes-jwt` manifest templating refactored (envsubst → Kustomize 6902)
- Folder reviews completed: `.circleci`, `.github`, `deploy-conjur`, `kubernetes-jwt`, `ansible-awx-tower`, `ansible`, `application-server-credential-provider`
- Docker images already migrated to GHCR using OCI-label template: `jenkins`, `postgres-companydb`, `push-to-file`, `push-to-k8s-secrets`

---

## Phase 1 — Sanitize HEAD

> Block-class. Even though demo creds are mostly inactive, GitHub push protection will reject
> tokens that match known formats, and a recruiter spotting a key in source still reads as
> "didn't tidy up." HEAD-only sweep — no history rewriting.

### TASK-101: Sanitize Spring Boot Conjur API key
**Priority:** BLOCKER · **Category:** Security · **Effort:** S
**Files:**
- [springboot-sdk/compiled/application-dev.properties](springboot-sdk/compiled/application-dev.properties)
- [springboot-sdk/compiled/application-prod.properties](springboot-sdk/compiled/application-prod.properties)
- [springboot-sdk/code/demo-app/src/main/resources/application-dev.properties](springboot-sdk/code/demo-app/src/main/resources/application-dev.properties)
- [springboot-sdk/code/demo-app/src/main/resources/application-prod.properties](springboot-sdk/code/demo-app/src/main/resources/application-prod.properties)

**Context:** All four files contain `conjur.authn-api-key=3vzrrwa3zfmp841572hxg3s3xmjr367r2w43fee94c33bntz4ska2n8` and the lab tenant URL `https://assaf-lab.secretsmgr.cyberark.cloud/api`.

**Action:**
1. Replace key with `<your-conjur-api-key>`.
2. Replace `assaf-lab` with `<your-tenant>`.
3. Add `springboot-sdk/compiled/` to `.gitignore` (it's a build output) and untrack — see TASK-110.
4. Document the placeholders in `springboot-sdk/README.md`.

**Acceptance:** No 32+ char alphanumeric key strings remain; no `assaf-lab` occurrences in `springboot-sdk/`.

---

### TASK-102: Sanitize Cognito IDP_CLIENT_SECRET in intro-demo
**Priority:** BLOCKER · **Category:** Security · **Effort:** S
**Files:**
- [intro-demo/webapp/.env](intro-demo/webapp/.env)
- [intro-demo/scripts/get-secret.sh](intro-demo/scripts/get-secret.sh)
- [intro-demo/scripts/get-jwt.sh](intro-demo/scripts/get-jwt.sh)

(Sister files in `jwt-demo/` are removed by TASK-302 since the folder is a duplicate.)

**Context:** `IDP_CLIENT_SECRET=15i4e2p9qtpictt1n31f782c9c65m3jquq57jkijhd9cehu3i5gk`, `IDP_CLIENT_ID=7j03g529sdski9nde886qac460`, `COGNITO_DOMAIN=eu-west-2fdn0jciev` all real-looking Cognito values.

**Action:**
1. Replace secret with `<your-cognito-client-secret>`.
2. Replace ID + domain with placeholders.
3. Rename `intro-demo/webapp/.env` → `intro-demo/webapp/.env.example`; gitignore the original name.
4. Sanitize the same patterns in `intro-demo/ansible/safe-onboarding.yml` if any creds there.

**Acceptance:** `git grep "15i4e2p9"` clean; only `.env.example` tracked, not `.env`.

---

### TASK-103: Sanitize SIA test script
**Priority:** BLOCKER · **Category:** Security · **Effort:** S
**File:** [secure-ai-access/database/02-test-connectivity-with-sia.sh](secure-ai-access/database/02-test-connectivity-with-sia.sh)

**Context:** Contains `MFA_TOKEN=cybrsso90oEkm1CogAkp+Rqa7JDPK3juKDp5Ec7hW7Ed6i0kyw=`, `TENANT_SUBDOMAIN="tiger-prod"`, `CYBERARK_USER="ahazan@tiger.com"`, `TARGET_FQDN="ec2-13-135-62-241.eu-west-2.compute.amazonaws.com"`.

**Action:** Replace each with explicit placeholders (`<your-cached-mfa-token>`, `<your-tenant-subdomain>`, `<your-identity-username>`, `<your-postgres-fqdn>`); add a `# Fill these in` block at the top.

**Acceptance:** No `cybrsso`-prefixed strings, no `tiger`, no real EC2 hostnames.

---

### TASK-104: Sanitize DPA postgres script
**Priority:** BLOCKER · **Category:** Security · **Effort:** S
**File:** [dynamic-privileged-access/rds-postgres-ephermeal-access.sh](dynamic-privileged-access/rds-postgres-ephermeal-access.sh)

**Context:** Contains `PGPASSWORD="vOFR3OOd6IQA+HpF0Hlyp2CI6mulGcz1IFnNr27o1yI="`, `USERNAME=assaf.hazan@cyberarklab.com`, `POSTGRES_HOST=cw-postgres.clv2dmjtgp2g.us-east-2.rds.amazonaws.com`. Filename also has typo `ephermeal`.

**Action:**
1. Replace password, username, host with placeholders.
2. Rename file to `rds-postgres-ephemeral-access.sh`.
3. Create `dynamic-privileged-access/README.md` (currently missing).

**Acceptance:** No `assaf.hazan` or `cyberarklab`; no real RDS hostnames; file renamed with correct spelling.

---

### TASK-105: Repo-wide sweep for personal/lab identifiers
**Priority:** BLOCKER · **Category:** Security · **Effort:** M
**Depends on:** TASK-101..104

**Context:** `git grep -i` for `tiger|cyberarklab|assaf-lab|assaf\.hazan|ahazan` returns 22+ files. After targeted tasks, do a final sweep — focus on Bruno/Postman JSON collections which often persist tenant URLs and tokens inside `value` fields.

**High-suspicion files:**
- [secure-cloud-access/SCA-GCP.md](secure-cloud-access/SCA-GCP.md)
- [springboot-sdk/ansible/safe-onboarding.yml](springboot-sdk/ansible/safe-onboarding.yml)
- [intro-demo/ansible/safe-onboarding.yml](intro-demo/ansible/safe-onboarding.yml)
- [databricks/ansible/safe-onboarding.yml](databricks/ansible/safe-onboarding.yml)
- [credential-provider/bruno/cp-pcloud-onboarding.json](credential-provider/bruno/cp-pcloud-onboarding.json)
- [bruno-collections/pcloud/pcloud.json](bruno-collections/pcloud/pcloud.json)
- [central-credential-provider/bruno/ccp-pcloud-onboard.json](central-credential-provider/bruno/ccp-pcloud-onboard.json)
- [aws-iam/elastic/python/ec2-dynamic-secret-sts.py](aws-iam/elastic/python/ec2-dynamic-secret-sts.py)
- [application-server-credential-provider/bruno/cp-pcloud-onboarding.json](application-server-credential-provider/bruno/cp-pcloud-onboarding.json)

**Action:**
1. `git grep -nE "(tiger|cyberarklab|assaf-lab|assaf\.hazan|ahazan|cybrsso)"` — review every hit.
2. Open Bruno/Postman collections; sanitize `value` fields for tenant URLs, usernames, tokens.
3. `git grep -nE "[A-Za-z0-9+/=]{40,}"` — manual review of remaining base64-shaped strings.

**Acceptance:** All five identifier patterns grep clean; Bruno/Postman collections reviewed.

---

### TASK-106: Replace internal hostnames + private IPs in kubernetes-jwt-priv-cloud
**Priority:** BLOCKER · **Category:** Security · **Effort:** S
**Files:**
- [kubernetes-jwt-priv-cloud/manifests/00-add-custom-dns.yml](kubernetes-jwt-priv-cloud/manifests/00-add-custom-dns.yml)
- [kubernetes-jwt-priv-cloud/manifests/07-push-to-file-springboot.yml](kubernetes-jwt-priv-cloud/manifests/07-push-to-file-springboot.yml)
- [images/postgres-companydb/.env](images/postgres-companydb/.env)
- [application-server-credential-provider/bruno/cp-pcloud-onboarding.json](application-server-credential-provider/bruno/cp-pcloud-onboarding.json)
- [credential-provider/bruno/cp-pcloud-onboarding.json](credential-provider/bruno/cp-pcloud-onboarding.json)

**Context:** Hardcoded `172.16.0.128 aws-pub-lab` / `172.16.0.169 proxy` in CoreDNS; `ip-172-16-0-128.eu-west-2.compute.internal` as datasource URL; `*.eu-west-2.compute.internal` as cert SAN.

**Action:** Replace literals with placeholder comments (`# replace with your VPC IP`, `<your-postgres-host>`, `*.example.internal`) and brief instructions.

**Acceptance:** No `172\.16\.0\.\d+`; no `ip-\d+-\d+-\d+-\d+\.\w+\.compute\.internal`.

---

### TASK-107: Standardize placeholder syntax across `.env.example` and install scripts
**Priority:** HIGH · **Category:** Security · **Effort:** S
**Files:**
- [ansible/scripts/.env.example](ansible/scripts/.env.example)
- [ansible-awx-tower/manifests/awx-secret.env.example](ansible-awx-tower/manifests/awx-secret.env.example)
- [credential-provider/scripts/01-install-agent.sh](credential-provider/scripts/01-install-agent.sh)
- [application-server-credential-provider/scripts/01-install-agent.sh](application-server-credential-provider/scripts/01-install-agent.sh)

**Context:** Mix of placeholder styles: `your_api_key_here`, `MySuperCoolPassword`, `your_vault_password`, `${VAR:-"10.0.0.1"}`. None are leaks but inconsistent reads as careless.

**Action:** Pick one style (recommend `<your-X>`) and apply across all `.env.example` files and inline placeholders in install scripts.

**Acceptance:** All placeholders follow one convention.

---

### TASK-108: Final HEAD-only secret scan
**Priority:** BLOCKER · **Category:** Security · **Effort:** S
**Depends on:** TASK-101..107

**Context:** Defense in depth. Owner has decided not to rewrite history; this scan verifies HEAD is clean. History will keep its original commits — this is an accepted risk documented in "Out of scope."

**Action:**
1. `gitleaks detect --source . --no-git` (HEAD only, ignore history).
2. `trufflehog filesystem .` for entropy-based detection.
3. `grep -rE "[A-Za-z0-9+/=]{40,}" --include="*.{sh,yml,yaml,json,properties,env,py}" .` — manual review.
4. Resolve every finding before completing.

**Acceptance:** All three scanners exit clean on HEAD.

---

### TASK-109: Untrack `CLAUDE..md` and add to `.gitignore`
**Priority:** HIGH · **Category:** Structure · **Effort:** S

**Context:** `CLAUDE..md` (double dot) is a personal AI-review prompt. Owner confirmed it should not be in the public repo. The malformed filename (two dots) is also a hygiene issue.

**Action:**
1. `git rm --cached CLAUDE..md` (keep file locally).
2. Add `CLAUDE.md`, `CLAUDE..md`, `claude.md` to `.gitignore` (covering casing variants and the typo).
3. Verify it's gone from `git ls-files`.

**Acceptance:** `git ls-files | grep -i claude` returns nothing tracked at root.

---

### TASK-110: Fix `.gitignore` correctness
**Priority:** HIGH · **Category:** Structure · **Effort:** S
**File:** [.gitignore](.gitignore)

**Context:** Current `.gitignore`:
```
**/*.log
node_modules/
**/*.claude
```
Issues:
- `**/*.claude` matches files ending in `.claude`, NOT the `.claude/` directory it was meant to ignore.
- Missing patterns for build artifacts seen in this repo: `*.env` (with `!*.env.example`), `*.dbc`, `*.war`, `*.jar`, `*.class`, `target/`, `compiled/`, `__pycache__/`, `.DS_Store`.
- `springboot-sdk/compiled/` contains build output (the `.properties` files with leaked keys) — should be regenerated, not committed.

**Action:**
1. Replace `**/*.claude` with `.claude/`.
2. Add the missing patterns (negation `!*.env.example` so templates stay tracked).
3. Run `git ls-files | grep -E '\.(env|dbc|war|jar|class)$|target/|compiled/'` — for each match, `git rm --cached` if it should not be tracked.
4. Add `CLAUDE..md` per TASK-109.

**Acceptance:** `.claude/` dir gitignored; no `.dbc`/`.war`/`.jar`/`.class` tracked; `compiled/` and `target/` gitignored.

---

## Phase 2 — Image migration (free-tier optimized)

> Free-tier GHCR has storage limits — minimize per-image size. The 4 already-migrated images establish
> the template (OCI labels block + MIT license + repo source link). Apply consistently to the rest,
> then update every manifest reference in one pass.

### Migrated reference template (use as the pattern)
```dockerfile
LABEL org.opencontainers.image.authors="assafjh"
LABEL org.opencontainers.image.source="https://github.com/assafjh/cybr-demos"
LABEL org.opencontainers.image.description="<one-line purpose>"
LABEL org.opencontainers.image.licenses="MIT"
```

### TASK-201: Migrate remaining 5 images to GHCR
**Priority:** HIGH · **Category:** Code · **Effort:** M
**Files:**
- [images/secretless/Dockerfile](images/secretless/Dockerfile)
- [images/spring-boot-zoo/Dockerfile](images/spring-boot-zoo/Dockerfile)
- [images/summon/Dockerfile](images/summon/Dockerfile)
- [images/rest-api-app-jwt/Dockerfile](images/rest-api-app-jwt/Dockerfile) *(may be removed by TASK-202)*
- [images/rest-api-app-authenticator-client/Dockerfile](images/rest-api-app-authenticator-client/Dockerfile) *(may be removed by TASK-202)*

**Context:** All 5 use the legacy `LABEL maintainer=AssafHazan` pattern; missing OCI metadata; no licensing/source links. Migration target: `ghcr.io/assafjh/<name>:<tag>`.

**Action:**
1. Replace `LABEL maintainer=AssafHazan` with the 4-line OCI block above.
2. Build, push to `ghcr.io/assafjh/<image>:<tag>`.
3. Verify reachability anonymously (free tier images need to be marked public).

**Acceptance:** All 5 images present and pullable from `ghcr.io/assafjh/*`; OCI labels visible via `docker inspect`.

---

### TASK-202: Deduplicate `rest-api-app-jwt` and `rest-api-app-authenticator-client`
**Priority:** HIGH · **Category:** Structure · **Effort:** S

**Context:** `diff -r images/rest-api-app-jwt images/rest-api-app-authenticator-client` returns no differences. Two image names for one Dockerfile + one set of scripts.

**Action:**
1. Decide which name keeps (recommend: `rest-api-app` — one canonical name, since both currently produce the same artifact).
2. Update any manifests / docs referencing the dropped name.
3. `git rm -r` the duplicate folder.

**Acceptance:** Only one `rest-api-app*` image folder under `images/`; no manifest or README references the removed name.

---

### TASK-203: Refresh pinned `summon` and `summon-conjur` binary versions
**Priority:** MEDIUM · **Category:** Code · **Effort:** S
**File:** [images/summon/Dockerfile](images/summon/Dockerfile)

**Context:** Pinning the Alpine *base* on the mini-wrapper images (push-to-file, push-to-k8s-secrets, secretless, rest-api-app-*) is not worth it — they install only `dumb-init`/`curl`, which haven't broken across Alpine minors, and pinning just freezes in CVEs. **Stays as `alpine:latest`.**

What *does* deserve attention: this Dockerfile downloads `summon v0.9.6` and `summon-conjur v0.7.1` from GitHub releases — both ~5 years old. Pinned at the artifact level, not the base. If either has a known CVE, the image ships it.

**Action:**
1. Check current latest releases of `cyberark/summon` and `cyberark/summon-conjur`.
2. If newer releases exist, update the URLs and rebuild. Smoke-test the demo that consumes this image.
3. Optionally: add a SHA256 checksum verification step to the curl-tar pipeline.

**Acceptance:** Summon binaries are at current upstream versions; demo using this image still works.

---

### TASK-204: Convert pre-built artifacts to multi-stage builds + CI

**Umbrella scope.** Every project that currently ships a pre-built JAR/WAR/`compiled/`/`node_modules/`
gets converted to: source in repo, multi-stage Dockerfile builds it, GitHub Actions packages and pushes
to GHCR. No build artifacts tracked. Artifact-by-artifact map below.

**Reference pattern (apply per Java project):**
```dockerfile
# ---- build stage ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -B -q dependency:go-offline      # cache layer
COPY src ./src
RUN mvn -B -q -DskipTests package

# ---- runtime stage ----
FROM eclipse-temurin:21-jre-alpine
COPY --from=build /src/target/*.jar /app/app.jar
ENTRYPOINT ["java","-jar","/app/app.jar"]
```

CI: `docker buildx build` with `cache-from`/`cache-to: type=gha` for cross-run cache; push to `ghcr.io/assafjh/<image>:<tag>`.

---

#### TASK-204a: Rewrite Spring Boot consumer — flagship demo
**Priority:** HIGH · **Category:** Code · **Effort:** L (≈1 day)
**Files:**
- Replace [code/spring-boot-zoo/](code/spring-boot-zoo/) with new module — proposed name `code/spring-boot-companydb` or similar, name TBD by owner.
- Retire [images/spring-boot-zoo/](images/spring-boot-zoo/) and the committed [images/spring-boot-zoo/demo-0.0.1-SNAPSHOT.jar](images/spring-boot-zoo/demo-0.0.1-SNAPSHOT.jar).
- Update consumers: [kubernetes-jwt/manifests/{06,07}-*.yml](kubernetes-jwt/manifests/), [kubernetes-cert/manifests/{06,07}-*.yml](kubernetes-cert/manifests/), [kubernetes-jwt-priv-cloud/manifests/{06,07}-*.yml](kubernetes-jwt-priv-cloud/manifests/), [images/secretless/Dockerfile](images/secretless/Dockerfile) (env defaults `DB_NAME=vet, TABLE_NAME=zoo`).

**Context:** The existing `code/spring-boot-zoo` doesn't do what the demo claims:
- **No hot-reload.** [DatabaseRunner.java:21](code/spring-boot-zoo/src/main/java/com/example/demo/bl/DatabaseRunner.java#L21) is `@Scheduled(fixedRate=10000)` polling `findAll()` over a static `DataSource`. Password is read once at startup — restarting the pod is required for rotation.
- **🚨 Logs the password** at INFO level every 10s ([DatabaseRunner.java:26](code/spring-boot-zoo/src/main/java/com/example/demo/bl/DatabaseRunner.java#L26)). In a CyberArk Conjur portfolio, this is the single most damaging line in the repo.
- **EOL framework.** Spring Boot 2.7.8 reached EOL Nov 2023; uses `javax.persistence` (Jakarta EE 8 namespace).
- **`Lombok @Data` on JPA entity** — anti-pattern (breaks `equals`/`hashCode` with proxies/lazy loading).

**Owner-confirmed direction:** rewrite from scratch using **Spring Cloud Config refresh** to demonstrate the actual hot-reload value prop. Java 21 + Spring Boot 3.x.

**Action:**
1. New Maven module under `code/<chosen-name>/`:
   - Spring Boot 3.x parent, Java 21 (`maven.compiler.release=21`).
   - Dependencies: `spring-boot-starter-data-jpa`, `spring-boot-starter-actuator`, `spring-cloud-starter` (+ Spring Cloud Config Client or Spring Cloud Kubernetes file watcher), PostgreSQL driver.
   - `application.properties` references `${spring.datasource.password}` from a file that the Conjur sidecar updates.
   - File watcher trigger — either `spring-cloud-kubernetes-fabric8-config` watching the mounted file, or a custom `WatchService` bean that emits `RefreshEvent`.
   - `@RefreshScope` on the `DataSource` bean so HikariCP is rebuilt on refresh.
   - Schema: `companydb` tables (verify schema in [images/postgres-companydb/demo-db.sql](images/postgres-companydb/demo-db.sql)).
   - Actuator endpoints: `/actuator/health/db`, `/actuator/info` with build metadata, `/actuator/refresh` to manually trigger.
   - Logging: log only that a refresh occurred and the new connection succeeded — **never the password value**.
2. Multi-stage Dockerfile co-located with source. No separate `images/spring-boot-zoo/`.
3. CI workflow `.github/workflows/build-spring-boot-consumer.yml` triggers on changes to the source folder.
4. Update K8s manifests in the three demos that consume this image — change `image: docker.io/assafhazan/spring-boot-zoo` → `ghcr.io/assafjh/<new-name>`, update env vars (`DB_NAME`, `TABLE_NAME`) to match companydb.
5. Update `images/secretless/Dockerfile` env defaults to companydb.
6. Test `@SpringBootTest` with Testcontainers PostgreSQL: insert row → query → trigger password change in container → verify next query succeeds without restart.

**Acceptance:**
- [ ] No occurrence of `password.*=` followed by an actual secret in any log statement (review `git grep -nE "log\.(info|debug|trace).*[Pp]assword"`).
- [ ] Live demo: `kubectl rollout` not required after `kubectl edit secret`/sidecar refresh — rotation is observable in actuator logs and the next query succeeds.
- [ ] Pod starts on a clean cluster from manifests + image alone (no manual `mvn package`).
- [ ] No `vet`/`zoo` references remain in the three consuming demos.

---

#### TASK-204b: Re-route ZooServlet to companydb
**Priority:** MEDIUM · **Category:** Code · **Effort:** S (≈30 min)
**Files:**
- [application-server-credential-provider/code/demo-app/src/main/java/com/example/ZooServlet.java](application-server-credential-provider/code/demo-app/src/main/java/com/example/ZooServlet.java)
- [application-server-credential-provider/code/demo-app/src/test/java/com/example/ZooTest.java](application-server-credential-provider/code/demo-app/src/test/java/com/example/ZooTest.java)
- [application-server-credential-provider/code/demo-app/src/main/webapp/index.jsp](application-server-credential-provider/code/demo-app/src/main/webapp/index.jsp)
- [application-server-credential-provider/scripts/03-deploy-postgres-server.sh](application-server-credential-provider/scripts/03-deploy-postgres-server.sh)
- [application-server-credential-provider/scripts/04-configure-datasource.sh](application-server-credential-provider/scripts/04-configure-datasource.sh)

**Context:** The servlet code is well-structured — modern Jakarta servlet, dual-DataSource side-by-side comparison (`CyberArkDS` ASCP-managed vs `PostgresDS` standard), sanitized error display. Only the schema is legacy. No rewrite needed — only swap the SQL queries and column references.

**Action:**
1. Replace `SELECT * FROM zoo` with the companydb equivalent (e.g., `SELECT id, name, email, signup_date FROM customers LIMIT 50` — verify schema).
2. Update column references in [ZooServlet.java](application-server-credential-provider/code/demo-app/src/main/java/com/example/ZooServlet.java) (`type`/`caregiver`/`email` → companydb columns).
3. Update table headers in the HTML output to match.
4. Update `ZooTest.java` queries.
5. Update `index.jsp` if it references zoo directly (verify — file is large, check first).
6. Update the postgres deployment scripts to use companydb.
7. Optional rename: `ZooServlet` → `CustomerServlet`, `ZooTest` → `CustomerTest`, `/zoo` URL → `/customers`. Cosmetic; if done, verify no broken refs.
8. Apply the multi-stage Maven build pattern (TASK-204 umbrella) — drop the committed WAR.

**Acceptance:**
- [ ] No `zoo`/`vet` references in `application-server-credential-provider/`.
- [ ] WAR is built by CI, not committed.
- [ ] Servlet still demonstrates the side-by-side `CyberArkDS` vs `PostgresDS` comparison.

---

#### TASK-204c: Reposition ASCP demo README around traditional-app-server framing
**Priority:** MEDIUM · **Category:** Docs · **Effort:** S
**Files:**
- [application-server-credential-provider/README.md](application-server-credential-provider/README.md)
- [README.md](README.md) (root scenario list)

**Context:** Calling ASCP "legacy" is imprecise — per [CyberArk's docs](https://docs.cyberark.com/credential-providers/latest/en/content/cp%20and%20ascp/lp_ascp.htm), the product is current and supported, but the *deployment scenario* it serves (traditional Java app servers — WebSphere/WebLogic/JBoss/Tomcat) is the legacy story. For cloud-native K8s, the equivalent pattern is Conjur Secrets Provider (sidecar/init), which is what TASK-204a will demonstrate.

The two demos are a strong portfolio "contrast pair" if positioned correctly: same problem (credential rotation without app restart), two product offerings, two deployment realities. A reader who picks up on this signals understanding of CyberArk's portfolio breadth.

Note: ASCP **Credential Mapper for WebLogic** specifically *was* deprecated Dec 31, 2023 — replaced by the **JDBC Driver Proxy**. The current Tomcat demo correctly uses the Driver Proxy pattern via `context.xml` JNDI, so no change needed; just worth a sentence in the README acknowledging awareness of the deprecation.

**Action:**
1. Open the README with: "Demonstrates CyberArk's integration pattern for **traditional Java application servers** (Tomcat, WebSphere, WebLogic, JBoss) — the JDBC Driver Proxy registers a JNDI factory that fetches credentials from CyberArk at runtime, no app code changes."
2. Add a "Modern equivalent" callout linking to TASK-204a's Spring Boot demo: "For Kubernetes-native deployments, see [link] — same problem solved with Conjur Secrets Provider sidecar + Spring Cloud Config refresh."
3. Optional: one-line note that the WebLogic Credential Mapper was deprecated in 2023 and the Driver Proxy is now the supported path — signals product currency.
4. Update the root README scenario blurb to reflect the framing shift.

**Acceptance:**
- [ ] README opens with the "traditional app servers" framing, not "legacy".
- [ ] Cross-link to the Spring Boot K8s demo present.
- [ ] Root README scenario line aligned.

---

#### TASK-204d: Multi-stage builds for remaining projects
**Priority:** MEDIUM · **Category:** Code · **Effort:** M
**Files:**
- [springboot-sdk/code/demo-app/](springboot-sdk/code/demo-app/) + [springboot-sdk/compiled/demo-app-0.0.1-SNAPSHOT.jar](springboot-sdk/compiled/demo-app-0.0.1-SNAPSHOT.jar)
- [springboot-sdk/code/jwks-generator/](springboot-sdk/code/jwks-generator/) + [springboot-sdk/compiled/jwks-generator-0.0.1-SNAPSHOT.jar](springboot-sdk/compiled/jwks-generator-0.0.1-SNAPSHOT.jar)
- [intro-demo/webapp/](intro-demo/webapp/) — `node_modules/` still tracked despite `.gitignore` entry
- [code/messenger/src/](code/messenger/src/)
- [credential-provider/compiled/CyberArkCredentialProvider.jar](credential-provider/compiled/CyberArkCredentialProvider.jar) — origin unclear

**Action:**
1. **springboot-sdk projects** — apply the umbrella Java pattern. Two modules (`demo-app`, `jwks-generator`); each gets a multi-stage Dockerfile. `compiled/` folder removed from tracking. The leaked `application-*.properties` files (TASK-101) should be regenerated by CI from a templated source, or live as `.example` files only.
2. **intro-demo/webapp** — `git rm --cached -r intro-demo/webapp/node_modules`; add multi-stage Node Dockerfile (`node:20-alpine` build with `npm ci --omit=dev` → `node:20-alpine` runtime, non-root user).
3. **code/messenger** — multi-stage Go Dockerfile (`golang:1-alpine` build → `gcr.io/distroless/static` runtime). Replace `code/messenger/build-compressed-binary.sh` if redundant, or keep as a "build locally" alternative with clear README note.
4. **credential-provider/compiled/CyberArkCredentialProvider.jar** — investigate origin:
   - If vendor JAR distributed by CyberArk: document its provenance + license + version in the demo README; keep as-is or fetch via CI from an official source.
   - If buildable from sources: locate sources, apply Maven multi-stage pattern, drop the committed JAR.
5. Add `compiled/` to `.gitignore` (covered partially by TASK-110).

**Acceptance:**
- [ ] `git ls-files | grep -E '\.(jar|war)$'` returns only Maven Wrapper JARs.
- [ ] No `compiled/` tracked.
- [ ] `node_modules/` gone from `intro-demo/webapp/`.
- [ ] Each project has a CI workflow that builds-and-pushes on source changes.
- [ ] Origin of `CyberArkCredentialProvider.jar` documented.

---

### TASK-205: Update all manifest image references to GHCR
**Priority:** HIGH · **Category:** Code · **Effort:** M
**Depends on:** TASK-201, TASK-202, TASK-203, TASK-204

**Context:** Dozens of manifests still reference `docker.io/assafhazan/*`. Doing this AFTER per-folder polish would mean editing every manifest twice.

**Action:**
1. `git grep -lE "(docker\.io/assafhazan|assafhazan/[a-z-]+)"` — list every file.
2. For each, replace with `ghcr.io/assafjh/<image>:<pinned-tag>`.
3. Smoke-test each demo touched (or document that it needs runtime verification before publishing).

**Acceptance:** No `docker.io/assafhazan` references remain; no `assafhazan/*` (without docker.io prefix) either.

---

### TASK-206: CI workflow for image build/lint/push
**Priority:** MEDIUM · **Category:** Code · **Effort:** M
**Depends on:** TASK-201..205

**Context:** Existing CI builds the 4 already-migrated images via separate workflows. Consolidate.

**Action:**
1. Single `.github/workflows/images.yml` that detects changed `images/*` directories and builds/pushes only those.
2. Add `hadolint` Dockerfile lint step.
3. Add a `docker run --rm <image> --help` (or equivalent) smoke step where applicable.
4. Set retention policy (image already added per recent commit `cbf7272 adding image retention policy` — verify it's correct).

**Acceptance:** Push to `images/*` triggers build of only changed images; hadolint runs; smoke step runs; old image versions are pruned per retention policy.

---

## Phase 3 — Foundation

### TASK-301: Document orphan top-level folders
**Priority:** HIGH · **Category:** Docs · **Effort:** L
**Files:** [README.md](README.md) + per-folder READMEs

**Context:** Root README lists 21 demos; repo has more top-level folders not enumerated. Owner decision: **document them all, do not remove except duplicates**.

**Folders needing READMEs (or expansion) + addition to root README:**
- `argocd` — has scripts/policies, no top-level README
- `code` — verify what this contains; document or move under another demo
- `databricks` — verify state on disk
- `dynamic-privileged-access` — created by TASK-104
- `intro-demo` — has webapp + lambda + ansible; rich, deserves a feature-quality README
- `kubernetes-jwt-priv-cloud` — close cousin of `kubernetes-jwt`; clarify the distinction in its README
- `python-conjur-sdk` — utility/demo; document what it shows
- `secure-ai-access`
- `secure-cloud-access`
- `springboot-sdk` — sister to other SDK demos; clarify scope

**Action:**
1. Write a README per folder following the existing per-demo template (purpose, prerequisites, setup, run commands, expected outcome).
2. Add each as a numbered entry in the root README "Scenarios" list with a one-line description.
3. Where a folder is a variant of another (`kubernetes-jwt-priv-cloud` vs `kubernetes-jwt`), explicitly state the difference at the top of the variant's README.

**Acceptance:** Every top-level folder either appears in the root README or is explicitly archived. Every kept demo folder has a README.

---

### TASK-302: Remove `jwt-demo` (byte-identical duplicate of `intro-demo`)
**Priority:** MEDIUM · **Category:** Structure · **Effort:** S
**Files:** [jwt-demo/](jwt-demo/)

**Context:** `diff -r intro-demo/{policies,scripts} jwt-demo/{policies,scripts}` returns no differences. `intro-demo` is the superset (adds `ansible/`, `lambda/`, `webapp/`). Per owner rule "remove only duplicates," `jwt-demo` qualifies.

**Action:**
1. Verify nothing in the repo references `jwt-demo` (`git grep "jwt-demo"`).
2. `git rm -r jwt-demo`.

**Acceptance:** `jwt-demo/` gone; no broken references.

---

### TASK-303: Strengthen root README for portfolio framing
**Priority:** MEDIUM · **Category:** Docs · **Effort:** M
**File:** [README.md](README.md)
**Depends on:** TASK-301

**Context:** Current README opens warmly but reads more like a personal page than a curated showcase. For recruiter-first reading, add structure that lets a senior engineer assess depth in 60 seconds.

**Action:**
1. Add "About me" section linking to LinkedIn / personal site (use the portfolio email — see open question Q1).
2. Add "Featured demos" section with 3 picks (deferred to owner — see open question Q2). Each gets a one-line "what this demonstrates."
3. Add "How to read this repo" section explaining the `policies/` / `scripts/` / `manifests/` / `images/` layout convention.
4. Tighten the disclaimer.

**Acceptance:** README answers "what / who / why / where to start" in the first screen.

---

## Phase 4 — Per-demo polish

> Carry forward from prior pass with the same FIX-vs-FLAG protocol. Run **after** Phase 2 image
> migration so manifests are touched only once.

- [x] `.circleci`
- [x] `.github`
- [x] `deploy-conjur`
- [x] `kubernetes-jwt`
- [x] `ansible-awx-tower`
- [x] `ansible`
- [x] `application-server-credential-provider`
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
- [ ] `databricks` *(verify state)*
- [ ] `code` *(verify state)*

### Per-folder review protocol

**FIX directly:** typos, missing `set -euo pipefail`, unquoted variables, wrong file extensions in README, broken paths, copy-paste errors, grammar.
**FLAG and ask:** anything where applying best practices changes behavior or requires a design decision (image tag pinning beyond Phase 2, templating approach, structural concerns).
**Never silently skip** — fix or flag.

**Conjur policy `.yml`:** logic untouched. Only descriptive variable names (`secret1` → `db_password` where context makes intent clear), comment polish, header-comment load-branch verified against the README.

**Shell `.sh`:** `set -euo pipefail`, `conjur whoami` before Conjur ops, quoted variables, secret-variable names match policy, professional comments.

**Kubernetes `.yml`:** consistent namespace / SA / labels, ConfigMap-driven Conjur connection details, FLAG-only on `:latest` for CyberArk-owned images, intentional empty fields untouched.

**README:** policy paths in `conjur policy` commands match folder structure, variable names match policies, script/manifest references include extensions, no absolute GitHub image URLs.

---

## Phase 5 — Efficiency review (scripts, manifests, dockerfiles)

> Owner explicitly asked for this. Not BLOCKER — these are quality-of-engineering signals
> for the portfolio audience. Run after per-demo polish so the surface is stable.

### TASK-501: Shell script efficiency sweep
**Priority:** MEDIUM · **Category:** Code · **Effort:** L

**Context:** Beyond the bash-hygiene checks already in Phase 4, look at:
- Repeated Conjur API calls that could be batched (`conjur variable set` loops vs single batch).
- Sequential `kubectl apply` operations that could be one `kubectl apply -k` (Kustomize).
- Idempotency — are scripts safe to re-run, or do they fail second time?
- `curl` calls without retry/timeout flags.
- Unnecessary `sleep` instead of polling for actual readiness.

**Action:** Per demo folder, list inefficiencies, FIX where the change is local, FLAG when it's a design call. Add `shellcheck` to CI (TASK-602).

**Acceptance:** Each demo's scripts re-run cleanly; obvious inefficiencies addressed; `shellcheck` passes.

---

### TASK-502: Manifest hardening sweep
**Priority:** MEDIUM · **Category:** Code · **Effort:** L

**Context:** Demos run in lab clusters but a portfolio reader will judge production-readiness signals:
- Resource `requests`/`limits` on every container (currently inconsistent).
- `imagePullPolicy: IfNotPresent` for pinned tags (avoid every-pod-pulls-from-GHCR — saves free-tier bandwidth).
- `securityContext: { runAsNonRoot: true, readOnlyRootFilesystem: true }` where the workload supports it.
- Liveness/readiness probes where the workload has a meaningful health signal.
- `resources.limits.memory` set to prevent runaway-pod kills cascading.

**Action:** Per manifest folder, add resource limits, set sensible pull policy, add probes/securityContext where they don't break the demo. FLAG demos that genuinely need elevated permissions.

**Acceptance:** Every Deployment/Pod has resource limits and pull policy; obvious hardening applied; FLAGS documented.

---

### TASK-503: Dockerfile efficiency on already-migrated images
**Priority:** LOW · **Category:** Code · **Effort:** M

**Context:** Free-tier GHCR — every byte counts. Current state of the 4 migrated images:
- `postgres-companydb` has hardcoded `POSTGRES_PASSWORD="123456"`. For a public demo image, either remove default (force user to set) or document loudly that this is intentional.
- `push-to-file` and `push-to-k8s-secrets` are near-twins — consider whether one image with an env-driven mode could replace both (saves storage; depends on whether they need to be separately tagged for clarity).
- All run as root — `USER` directive missing on the alpine-based ones.
- `apk update && apk add` without `--no-cache` on push-to-k8s-secrets (push-to-file has it). Inconsistent.

**Action:**
1. Add `--no-cache` to all `apk add` invocations.
2. Add `USER 1000:1000` (or similar non-root) where the entrypoint allows.
3. Decide on `postgres-companydb` password handling.
4. Decide on push-to-file/push-to-k8s-secrets consolidation (FLAG, owner call).

**Acceptance:** All images have `--no-cache` for apk; non-root where feasible; consolidation decision recorded.

---

## Phase 6 — Portfolio polish

### TASK-601: Architecture diagrams (Mermaid) for 3 featured demos
**Priority:** LOW · **Category:** Docs · **Effort:** L
**Depends on:** featured-demos decision (open question Q2)

**Action:** For each featured demo, add a Mermaid system-flow diagram showing trust boundary, who calls whom, where the secret enters/leaves. Inline so it renders on GitHub.

**Acceptance:** 3 demos have Mermaid diagrams with captions.

---

### TASK-602: CI quality gates beyond image builds
**Priority:** MEDIUM · **Category:** Code · **Effort:** M

**Action:**
1. `shellcheck` workflow over all `.sh`.
2. `yamllint` (relaxed) over all `.yml`/`.yaml`.
3. `markdownlint` + markdown-link-checker over all `.md`.
4. `gitleaks` on every push (HEAD-only since history is accepted as-is).
5. Surface as PR checks.

**Acceptance:** PR checks cover shell/yaml/markdown lint + secret scan.

---

## Final review

### TASK-701: Clean-clone walkthrough before going public
**Priority:** BLOCKER · **Category:** Final review · **Effort:** M
**Depends on:** Phase 1 + Phase 2 done; Phase 3..5 substantially done

**Action:**
1. Clone fresh: `git clone <local> /tmp/cybr-demos-test && cd /tmp/cybr-demos-test`.
2. Read root README cold. Note every confusion or broken link.
3. Pick one featured demo at random; run from README only.
4. Run `gitleaks detect`, `trufflehog filesystem .` once more on HEAD.
5. Walk every demo's image references and confirm `ghcr.io/assafjh/*` is reachable anonymously.

**Acceptance:** Stranger walkthrough produces zero blockers; scanners clean; owner comfortable telling a recruiter "skim this repo."

---

## Open questions

1. **Portfolio email** — switch from `assafjh@gmail.com` to a dedicated portfolio email? If yes, also update commit identity for the merge that closes Phase 1.
2. **Featured demos** — which 3 to highlight? My suggestion: `kubernetes-jwt`, `argocd` or `ansible-awx-tower`, `aws-iam`. Owner picks.
3. **GHCR tag strategy** — semver / git SHA / `latest`? Recommend pinned semver for images referenced in manifests + a moving `:latest` for human pulls. Owner confirms.

## Out of scope / explicitly decided against

- **Git history scrub.** 4 years of personal-portfolio history outweighs the cleanup benefit. Demo creds are mostly inactive; HEAD is sanitized. History will retain its original commits.
- **Customer-name concerns.** All tenants/identifiers are personal demo systems. No real customers, no contractual exposure.
- **Removing folders.** Every orphan gets documented (TASK-301). Only byte-identical duplicates removed (`jwt-demo`, possibly `rest-api-app-*`).
- **Rewriting demo logic.** Conjur policies, manifests, scripts assumed to work as authored. Review only fixes hygiene, sanitization, documentation, efficiency — never behavior.
- **Adding new demos.** Polish what exists; do not expand scope before publication.
- **Restructuring under a single CLI/Makefile.** Per-demo numbered-script convention is intentional and reads well in a portfolio context.
