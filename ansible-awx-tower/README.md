# 🔐 Ansible AWX / Tower Integration with Conjur
[![Package Status](https://github.com/assafjh/cybr-demos/actions/workflows/ansible-aws-demo.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/ansible-aws-demo.yml)

This repository demonstrates how to integrate CyberArk Conjur with Ansible AWX or Ansible Tower. The integration steps are identical for both platforms.

This demo showcases two distinct secret consumption methods:
1. **Machine Credential Injection:** Injecting a password directly into Ansible's core facts (`ansible_password`).
2. **Custom Credential Type Injection:** Pulling multiple application-specific secrets dynamically.

---

## 🏗️ 1. Deploy AWX Instance (Optional)

If you do not have a running AWX instance, you can deploy a lean, demo-ready instance on your Kubernetes node using the provided manifests.

*Note: The installation is based on the [AWX Operator GitHub](https://github.com/ansible/awx-operator) (v1.1.3).*

All modifications should be done within the `/manifests` folder.

### Step 1.1: Customize Kubernetes Manifests

**Modify `kustomization.yml`**
1. **Custom Certificate (Optional):** Uncomment lines regarding `awx-secret-tls` and ensure your `tls.crt` and `tls.key` files are in the folder.
2. **Postgres Configuration:** Define your database limits or bypass logic.
3. **Set Admin Password:** *IMPORTANT: Use the `.env` setup as described in the manifest section instead of plain text if pushing to public repos.*
4. **Namespace:** Change `namespace: awx` if required.

**Modify `pv.yml` (Persistent Volume)**
Create the host path folder on your node:
```bash
AWX_PROJECTS_PARENT_PATH=$HOME
mkdir -p "$AWX_PROJECTS_PARENT_PATH"/awx-data/projects
```
Then, update line #31 in `pv.yml` to match this path.

**Modify `awx.yml`**
1. Update line #14 with your external hostname: `hostname: <your-awx-machine-fqdn>`.
2. Uncomment sections for custom certificates, Postgres PVs, or Resource limits based on your node's capacity.

### Step 1.2: Deploy
```bash
scripts/01-deploy-axw-operator-and-instance.sh
```

---

## 📜 2. Loading Conjur Policies

To adhere to the principle of least privilege, policies are split between **Base** (Infrastructure) and **App** (Application).

### Option A: Conjur Enterprise (On-Premise)

1. **Login as admin and load the Base policy:**
   ```bash
   conjur login -i admin
   conjur policy update -b root -f policies/conjur-onprem/01-base.yml | tee -a base.log
   conjur logout
   ```
2. **Login as `ansible-admin01` and load the App policy:**
   *(Use the API key from `base.log`)*
   ```bash
   conjur login -i ansible-admin01
   conjur policy update -b data/ansible -f policies/conjur-onprem/02-define-ansible-branch.yml | tee -a app-policy.log
   ```

### Option B: Conjur Cloud

1. **Login as your Cloud admin and load the Base policy:**
   ```bash
   conjur login -i <username>
   conjur policy update -b data -f policies/conjur-cloud/01-base.yml | tee -a base.log
   conjur logout
   ```
2. **Login as `ansible-admin01` and load the App policy:**
   *(Use the API key from `base.log`)*
   ```bash
   conjur login -i ansible-admin01
   conjur policy update -b data/ansible -f policies/conjur-cloud/02-define-ansible-branch.yml | tee -a app-policy.log
   ```

### Populate Conjur Variables
Generate and inject secure values into the newly created variables (`ansible_password`, `db_password`, `api_key`, `ssh_key`):
```bash
scripts/03-populate-variables.sh | tee -a populate.log
```
*(Make sure you are still logged in to Conjur CLI before running this).*

---

## ⚙️ 3. Configure AWX Custom Credential Type

1. Log into the AWX/Tower UI.
2. Navigate to **Administration -> Credential Types** -> Click **Add**.
3. Name it: `Conjur Secrets`.
4. **Input Configuration (YAML):**
   ```yaml
   ---
   fields:
     - id: db_password
       type: string
       label: DB Password Path
       secret: true
     - id: api_key
       type: string
       label: API Key Path
       secret: true
     - id: ssh_key
       type: string
       label: SSH Key Path
       secret: true
   required:
     - db_password
     - api_key
     - ssh_key
   ```
5. **Injector Configuration (YAML):**
   ```yaml
   ---
   extra_vars:
     db_password: '{{ db_password }}'
     api_key: '{{ api_key }}'
     ssh_key: '{{ ssh_key }}'
   ```
6. Click **Save**.

---

## 🏢 4. Configure AWX Environment

### 4.1 Create Organization
1. Go to **Access -> Organizations** -> Click **Add**.
2. Name: `Conjur Demo`.
3. Click **Save**.

### 4.2 Create Project
1. Go to **Resources -> Projects** -> Click **Add**.
2. Name: `Conjur Demo Project`.
3. Organization: `Conjur Demo`.
4. Source Control Type: `Git`.
5. Source Control URL: `https://github.com/assafjh/cybr-demos.git`.
6. Source Control Branch: `ansible-awx-tower-playbooks` *(Change this to your actual branch name if different)*.
7. Click **Save**.

### 4.3 Create Inventory
1. Go to **Resources -> Inventories** -> Click **Add** -> **Add inventory**.
2. Name: `Conjur`.
3. Organization: `Conjur Demo`.
4. Click **Save**.

---

## 🔑 5. Configure Credentials in AWX

Navigate to **Resources -> Credentials** to create the following three credentials.

### Credential A: Conjur Instance Connection
1. Click **Add**.
2. Name: `Conjur Instance` | Organization: `Conjur Demo`.
3. Credential Type: `CyberArk Conjur Secrets Manager Lookup`.
4. **Fill Details:**
   - **Conjur URL:** `https://<your-conjur-fqdn>`
   - **API Key:** Use the API key from `app-policy.log` for `host/apps/awx-node`.
   - **Account:** `conjur`
   - **Username:** `host/data/ansible/apps/awx-node`
5. Test it against `data/ansible/apps/safe/db_password` and **Save**.

### Credential B: Application Variables (Custom Type)
1. Click **Add**.
2. Name: `Conjur Variables` | Organization: `Conjur Demo`.
3. Credential Type: `Conjur Secrets` (The one we created in Step 3).
4. **Fill Details:** Link the `Conjur Instance` credential created above and specify the paths (e.g., `data/ansible/apps/safe/db_password`).
5. **Save**.

### Credential C: Machine Secret
1. Click **Add**.
2. Name: `Conjur Machine Secret` | Organization: `Conjur Demo`.
3. Credential Type: `Machine`.
4. **Fill Details:**
   - Username: `dummy` (or your actual target user)
   - Password: Click the key icon, select the `Conjur Instance` lookup, and enter `data/ansible/apps/safe/ansible_password`.
5. **Save**.

---

## 🚀 6. Execution & Job Templates

Navigate to **Resources -> Templates**.

### Demo 1: Application Secrets Retrieval
1. Click **Add -> Add job template**.
2. Name: `Conjur App Variables Demo`.
3. Job Type: `Run` | Inventory: `Conjur` | Project: `Conjur Demo Project`.
4. Playbook: `print-variables.yml`.
5. **Credentials:** Select `Conjur Variables`.
6. Click **Save** and then **Launch**.
7. *Observe the output dynamically printing the fetched `db_password`.*

### Demo 2: Machine Password Injection
1. Click **Add -> Add job template**.
2. Name: `Conjur Machine Secret Demo`.
3. Job Type: `Run` | Inventory: `Conjur` | Project: `Conjur Demo Project`.
4. Playbook: `print-machine-password.yml`.
5. **Credentials:** Select `Conjur Machine Secret`.
6. Click **Save** and then **Launch**.
7. *Observe the output confirming the injection of the `ansible_password`.*
