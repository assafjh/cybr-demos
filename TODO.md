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

## 🐳 Docker Images & CI/CD (GHCR)
- [ ] Migrate custom Docker images to GHCR.
- [ ] Create `.github/workflows/ci.yml` to build and push Docker images on changes.
- [ ] Add testing steps to `ci.yml` (Dockerfile linting with `hadolint`, basic container run tests).

## 🔎 Folder-by-Folder Quality Review

> ⚠️ **Instructions for LLM:**
> For each folder marked [ ], perform the following checks and mark [x] only after ALL checks pass.
> Do NOT mark [x] based on visual inspection alone — read and verify each file.
>
> **Conjur Policy files (`.yml`)** — DO NOT modify policy logic, paths, or structure. Only:
> - Fix variable/resource names to be descriptive (e.g., `secret1` → `db_password`) if the context makes the intent clear.
> - Improve inline comments to be professional and accurate.
> - Verify load branch in the file's header comment matches the README instructions for that folder.
> - Flag (do not fix) anything that looks structurally wrong — leave a comment for human review.
>
> **Shell scripts (`.sh`)** — check for:
> - Missing error handling on critical commands — add `if/then` guard where absent.
> - Auth check (`conjur whoami`) present before performing operations.
> - `set -euo pipefail` at the top.
> - Secret variable names match those defined in the corresponding policy file exactly.
> - Inline comments are clear and professional.
> - **DO NOT change script logic** unless it is clearly broken (e.g., referencing a path that does not exist) or causes a runtime error. Scripts were tested before being committed.
>
> **README files** — check for:
> - Policy file paths in `conjur policy` commands match the actual folder structure.
> - Variable names mentioned match those defined in policy files.
> - Diagrams or images that reference outdated policy structures — remove them.
> - Broken or redundant markdown (e.g., double-bracketed URLs).

- [x] `.circleci`
- [x] `.github`
- [ ] `deploy-conjur`
- [ ] `kubernetes-jwt`
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
- [ ] `upgrade-conjur-enterprise-version`
- [ ] `teamcity`
- [ ] `credential-provider`
- [ ] `central-credential-provider`
- [x] `application-server-credential-provider`

## 🏁 Final Review
- [ ] Review the repository as a clean clone before changing visibility to Public.