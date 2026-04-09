# Utils Functions Catalog

Shell utility functions for interactive use. All functions are automatically loaded via `personal_login.rc`.

## AWS Authentication

### `login_aws`

**File:** `login_aws.sh`  
**Description:** Authenticate with AWS SSO and configure EKS/ECR access  
**Usage:** `login_aws`  
**What it does:**

- Authenticates with cip-nonprod, cip-nonprod-party, and ciptooling-prod profiles
- Updates EKS kubeconfig for atanga and party clusters
- Configures ECR Docker login
- Sets CODEARTIFACT_AUTH_TOKEN environment variable

---

## Docker & ECR

### `ecr_docker_login`

**File:** `docker_utils.sh`  
**Description:** Login to ECR registry with automatic error recovery  
**Usage:** `ecr_docker_login <profile> <registry-url>`  
**Example:** `ecr_docker_login cip-nonprod 250300400957.dkr.ecr.ap-southeast-2.amazonaws.com`

### `fix_docker_credentials`

**File:** `docker_utils.sh`  
**Description:** Fix Docker credentials storage configuration errors  
**Usage:** `fix_docker_credentials`  
**What it does:** Creates/updates ~/.docker/config.json and removes problematic credsStore settings

---

## Git & Azure DevOps

### `new_branch`

**File:** `git_workflow.sh`  
**Description:** Create git branch from Azure DevOps work item  
**Usage:** `new_branch <story-number> [branch-type]`  
**Branch types:** feature (default), bugfix, format, refactoring  
**Examples:**

- `new_branch 12345` → Creates `AB#12345/feature-work-item-title`
- `new_branch 12345 bugfix` → Creates `AB#12345/bugfix-work-item-title`

**Prerequisites:** AZURE_DEVOPS_EXT_PAT must be configured (function prompts if not set)

### `configure_azure_devops_pat`

**File:** `git_workflow.sh`  
**Description:** Configure or update Azure DevOps Personal Access Token  
**Usage:** `configure_azure_devops_pat [-f|--force]`  
**Options:** `-f, --force` - Force update even if already configured

---

## Database Access

### `rds_token`

**File:** `rds_token.sh`  
**Description:** Generate RDS authentication token for PostgreSQL  
**Usage:** `rds_token [--party]`  
**Options:**

- (no flag) - Token for atanga_readonly@atanga-postgres-instance
- `--party` - Token for party_readonly@party-postgres-instance

### `party_sdt`

**File:** `party_sdt.sh`  
**Description:** Authenticate with Kerberos for Party SDT database  
**Usage:** `party_sdt [sit|qas]`  
**Environments:** sit (default), qas  
**What it does:**

- Fetches Kerberos credentials from AWS Secrets Manager
- Authenticates with kinit
- Sets environment variables (KERBEROS_PRINCIPAL, SDT_SERVER, SDT_DATABASE, etc.)
- Displays current Kerberos tickets

**Prerequisites:** AWS CLI with ciptooling-prod-party profile, kinit/klist commands

---

## Function Overview Table

| Function                     | Category | File            | Description                                |
| ---------------------------- | -------- | --------------- | ------------------------------------------ |
| `login_aws`                  | AWS      | login_aws.sh    | AWS SSO authentication + EKS/ECR config    |
| `ecr_docker_login`           | Docker   | docker_utils.sh | ECR authentication with error recovery     |
| `fix_docker_credentials`     | Docker   | docker_utils.sh | Fix Docker config.json credentials storage |
| `new_branch`                 | Git      | git_workflow.sh | Create branch from Azure DevOps work item  |
| `configure_azure_devops_pat` | Git      | git_workflow.sh | Setup/update Azure DevOps PAT              |
| `rds_token`                  | Database | rds_token.sh    | Generate RDS authentication token          |
| `party_sdt`                  | Database | party_sdt.sh    | Kerberos authentication for Party SDT      |

---

## Adding New Functions

When adding a new utility function:

1. **Add to appropriate file** (or create new file following naming pattern)
   - AWS-related → `login_aws.sh`
   - Docker/ECR → `docker_utils.sh`
   - Git/Azure DevOps → `git_workflow.sh`
   - Database → `rds_token.sh` or `party_sdt.sh`

2. **Use standard documentation header:**

   ```bash
   # function_name - Brief one-line description
   #
   # Usage:
   #   function_name <required-param> [optional-param]
   #
   # Parameters:
   #   required-param: Description
   #   optional-param: Description (default: value)
   #
   # Description:
   #   Detailed explanation
   ```

3. **Export for bash/zsh compatibility:**

   ```bash
   if [ -n "$BASH_VERSION" ]; then
       export -f function_name
   elif [ -n "$ZSH_VERSION" ]; then
       :
   fi
   ```

4. **Update this README** - Add function to appropriate section and overview table

---

## Files in utils/

| File                  | Purpose                                        |
| --------------------- | ---------------------------------------------- |
| `login_aws.sh`        | AWS authentication and configuration           |
| `docker_utils.sh`     | Docker and ECR utilities                       |
| `git_workflow.sh`     | Git and Azure DevOps workflow functions        |
| `rds_token.sh`        | RDS PostgreSQL authentication                  |
| `party_sdt.sh`        | Kerberos authentication for Party SDT database |
| `risk_rangers_env.sh` | Environment variables only (no functions)      |
