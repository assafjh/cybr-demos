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

## 🎯 Final Review
- [ ] Review the repository structure locally as a clean clone to ensure everything works out-of-the-box before changing visibility to Public.