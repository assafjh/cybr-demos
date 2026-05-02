# 🚀 Pre-Release TODO List

## 🔒 Security & Secrets (Critical)
- [x] Add `*.log` to the root `.gitignore` file.
- [x] Ensure no `*.log` files containing API keys/secrets are in the Git history. (Use `git filter-repo` or `BFG Repo-Cleaner` to remove them if necessary).
- [x] Rotate/Reset any real credentials, API keys, or tokens that might have been accidentally committed during testing.

## 🧹 Repository Cleanup
- [x] Remove `node_modules` from Git tracking: run `git rm -r --cached intro-demo/webapp/node_modules`.
- [x] Add `node_modules/` to the root `.gitignore`.

## 📝 Documentation Improvements
- [x] **Root README.md**: Add a personal introduction (e.g., "Hi, I'm Assaf..."), the purpose of the repo (Portfolio/Demos), and a "Technologies Used" section.
- [x] **Sub-folder READMEs**: Expand the READMEs in `ansible`, `jenkins`, `terraform`, `teamcity`, `circleci`, and `aws-iam` to include:
  - [x] Short description of what the demo achieves.
  - [x] Prerequisites (tools needed, versions).
  - [x] Basic instructions on how to run/deploy.

## 🛠️ Fixes & Formatting
- [x] **Relative Image Paths**: Convert absolute GitHub URLs for images to relative paths (e.g., `!alt text`) across all README files.
- [x] **Grammar & Typos**: Fix minor typos (e.g., change `How does the ... works?` to `work?` in the Kubernetes READMEs).

## 🏭 Industry Standard Files
- [x] Add `LICENSE` (e.g., MIT, Apache 2.0).
- [x] Add `SECURITY.md` (Vulnerability reporting process - highly recommended for Security SMEs).
- [ ] Add `CHANGELOG.md` (Optional: Track major updates to demos).

## 🐳 Docker Images & CI/CD (GHCR)
- [ ] Migrate custom Docker images (e.g., webapps, custom followers) to GitHub Container Registry (GHCR).
- [ ] Create `.github/workflows/ci.yml` to automatically build and push Docker images on changes.
- [ ] Add testing steps to the `ci.yml` workflow (e.g., Dockerfile linting using `hadolint`, basic container run tests).

## 🔎 Folder-by-Folder Quality Review (Standardization)
- [x] `.circleci`: Validate pipeline config, hardcoded values, and integration flow.
- [x] `.github`: Validate action workflows, runners setup, and Conjur steps.
- [ ] `deploy-conjur`: Validate deployment scripts and documentation.
- [ ] `kubernetes-jwt`: Validate manifests, policies, and instructions.
- [ ] `kubernetes-cert`: Validate manifests, policies, and instructions.
- [ ] `jenkins`: Validate CI pipeline syntax, logic, and documentation.
- [ ] `github-actions`: Validate action workflows and documentation.
- [ ] `circleci`: Validate CircleCI config and documentation.
- [ ] `aws-iam`: Validate Lambda scripts, IAM role configs, and docs.
- [ ] `terraform`: Validate `.tf` file formatting and provider config.
- [ ] `gitlab-ci`: Validate GitLab CI YAML and scripts.
- [ ] `rest-api`: Validate API call examples and documentation.
- [x] `ansible-awx-tower`: Validate AWX/Tower integration docs.
- [x] `ansible`: Validate playbooks structure and documentation.
- [ ] `azure-devops`: Validate scripts, pipeline YAML formats, and docs.
- [ ] `kubernetes-follower`: Validate manifests and Conjur policies.
- [ ] `custom-certificates`: Validate scripts for cert generation and loading.
- [ ] `kubernetes-external-secrets-operator`: Validate ESO manifests.
- [ ] `upgrade-conjur-enterprise-version`: Validate upgrade scripts and flow.
- [ ] `teamcity`: Validate TeamCity integration instructions.
- [ ] `credential-provider`: Validate CP agent config and Java code.
- [ ] `central-credential-provider`: Validate CCP examples (REST/SOAP).
- [x] `application-server-credential-provider`: Validate Tomcat/Jakarta setup.

## � Final Review
- [ ] Review the repository structure locally as a clean clone to ensure everything works out-of-the-box before changing visibility to Public.