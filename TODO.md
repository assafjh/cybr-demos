# 🚀 Pre-Release TODO List

## 🔒 Security & Secrets (Critical)
- [x] Add `*.log` to the root `.gitignore` file.
- [x] Ensure no `*.log` files containing API keys/secrets are in the Git history. (Use `git filter-repo` or `BFG Repo-Cleaner` to remove them if necessary).
- [x] Rotate/Reset any real credentials, API keys, or tokens that might have been accidentally committed during testing.

## 🧹 Repository Cleanup
- [x] Remove `node_modules` from Git tracking: run `git rm -r --cached intro-demo/webapp/node_modules`.
- [x] Add `node_modules/` to the root `.gitignore`.

## 📝 Documentation Improvements
- [x] **Root README.md**: Add a personal introduction, the purpose of the repo (Portfolio/Demos), and a "Technologies Used" section.
- [x] **Sub-folder READMEs**: Expand the READMEs in `ansible`, `jenkins`, `terraform`, `teamcity`, `circleci`, and `aws-iam` to include a short description, prerequisites, and basic instructions.

## 🛠️ Fixes & Formatting
- [x] **Relative Image Paths**: Convert absolute GitHub URLs for images to relative paths across all README files.
- [x] **Grammar & Typos**: Fix minor typos across all README files.

## 🏭 Industry Standard Files
- [x] Add `LICENSE`.
- [x] Add `SECURITY.md`.
- [ ] Add `CHANGELOG.md` (Optional).

## 🔧 Open Questions
- [x] **Manifest templating**: Switched `kubernetes-jwt/scripts/10-deploy-manifest-08.sh` from `envsubst` to Kustomize (JSON 6902 patches). Apply the same pattern to any other folder that uses `envsubst` for manifest injection.

## 🐳 Docker Images & CI/CD (GHCR)
> ⚠️ **Do this BEFORE completing remaining folder reviews.** All remaining folders reference `docker.io/assafhazan/*` images — finishing reviews first means touching every manifest twice.
>
> **Decisions needed before starting:**
> - Tagging strategy: semver / `latest` / git SHA?
> - "Slim" definition per image: multi-stage build? distroless base?
> - Backward compatibility: hard-cut to GHCR only, or keep `docker.io` mirrors?
> - Scope: migrate ALL images in `images/` folder, or only those actively used in demos?

- [ ] Inventory `images/` folder — list all custom images, their base images, and which manifests reference them.
- [ ] Decide on tagging strategy and slim-image approach (planning session).
- [ ] Migrate custom Docker images to GHCR (`ghcr.io/assafjh/*`).
- [ ] Update all manifest image references from `docker.io/assafhazan/*` to `ghcr.io/assafjh/*`.
- [ ] Create `.github/workflows/ci.yml` to build and push Docker images on changes.
- [ ] Add testing steps to `ci.yml` (Dockerfile linting with `hadolint`, basic container run tests).

## 🔎 Folder-by-Folder Quality Review

> ⚠️ **Instructions for LLM:**
> For each folder marked [ ], perform the following checks and mark [x] only after ALL checks pass.
> Do NOT mark [x] based on visual inspection alone — read and verify each file.
>
> **Decision protocol — FIX vs FLAG:**
> - **FIX directly**: typos, missing `set -euo pipefail`, unquoted variables, wrong file extensions in README, broken paths, copy-paste errors (e.g., wrong username), missing `.sh`/`.yml` extensions, grammar issues.
> - **FLAG and ask**: anything where applying best practices would change behavior or require a design decision (e.g., image tag pinning, templating approach, structural concerns in policies). State the issue clearly, give a recommendation, and wait for approval.
> - **Never silently skip** something that genuinely looks wrong — either fix it or flag it. Ignoring real issues defeats the purpose of the review.
>
> **Conjur Policy files (`.yml`)** — the logic, paths, and structure were tested and must not be changed. Only:
> - Fix variable/resource names to be descriptive (e.g., `secret1` → `db_password`) if the context makes the intent clear.
> - Improve inline comments to be professional and accurate.
> - Verify the load branch in the file's header comment matches the README instructions for that folder.
> - FLAG (do not fix) anything that looks structurally wrong — state it clearly for human review.
>
> **Shell scripts (`.sh`)** — check for:
> - Missing `set -euo pipefail` at the top.
> - Auth check (`conjur whoami`) present before performing Conjur operations.
> - Unquoted variables that could cause word-splitting.
> - Secret variable names match those defined in the corresponding policy file exactly.
> - Inline comments are clear and professional.
>
> **Kubernetes manifests (`.yml`)** — check for:
> - Namespace, ServiceAccount, and label names are consistent across all manifests in the folder.
> - Conjur connection details (URL, account, authenticator ID) use ConfigMap references, not hardcoded values.
> - Image tags using `latest` for CyberArk-owned images — FLAG only, do not change without asking.
> - Empty fields left intentionally for demo documentation — do not add comments unless they cause a real runtime issue.
>
> **README files** — check for:
> - Policy file paths in `conjur policy` commands match the actual folder structure.
> - Variable names mentioned match those defined in policy files.
> - Script/manifest references include the correct file extension.
> - Absolute GitHub image URLs — convert to relative paths.
> - Broken or redundant markdown (e.g., double-bracketed URLs).

- [x] `.circleci`
- [x] `.github`
- [x] `deploy-conjur`
- [x] `kubernetes-jwt`
- [ ] `kubernetes-cert`
- [ ] `jenkins`
- [ ] `github-actions`
- [ ] `circleci`
- [ ] `aws-iam`
- [ ] `terraform`
- [ ] `gitlab-ci`
- [ ] `rest-api`
- [x] `ansible-awx-tower`
- [x] `ansible`
- [ ] `azure-devops`
- [ ] `kubernetes-follower`
- [ ] `custom-certificates`
- [ ] `kubernetes-external-secrets-operator`
- [ ] `kubernetes-jwt-priv-cloud`
- [ ] `upgrade-conjur-enterprise-version`
- [ ] `teamcity`
- [ ] `credential-provider`
- [ ] `central-credential-provider`
- [x] `application-server-credential-provider`

## 🏁 Final Review
- [ ] Review the repository as a clean clone before changing visibility to Public.