# KB WSL Provisioning Scripts

Bash automation for Kiwibank's WSL development environment setup.

## Architecture

**Execution Flow:** Windows → WSL → Runtime

- `get-latest-wsl.sh` - Runs from Git Bash on Windows to install/upgrade WSL
- `personal_provisioning.sh` - Auto-runs inside WSL on first login for environment setup
- `personal_login.rc` - Sourced by shell on every session for environment/utilities
- `tools/` - One-time installation scripts (Oh My Zsh, software removal)
- `utils/` - Reusable shell functions for interactive use (AWS login, ECR, git workflows)

## Bash Script Conventions

**Safety flags (required for all new scripts):**

```bash
set -o errexit   # Exit on any error
set -o pipefail  # Pipe failures propagate
set -o nounset   # Error on undefined variables
```

**Color coding (consistent across all scripts):**

```bash
RED='\033[1;31m'     # Errors, critical warnings
YELLOW='\033[1;33m'  # User prompts, important notices
GREEN='\033[1;32m'   # Success messages
BLUE='\033[1;34m'    # Section headers
NC='\033[0m'         # Always reset after colored text
```

**Error handling patterns:**

- Direct command checks: `if ! command; then` (not `$?`)
- File existence: `[ ! -f "$FILE" ]` before operations
- User confirmation: `read -r -p "prompt" var` (always use `-r`)
- Environment detection: `grep -qi microsoft /proc/version` for WSL vs Windows

## Key Principles

1. **Idempotency**: Scripts must handle re-runs gracefully (check if already installed/configured)
2. **Environment-aware**: Detect Windows vs WSL context and fail fast if wrong
3. **Modular functions**: Extract reusable logic into functions with clear documentation
4. **User feedback**: Color-code messages appropriately, show progress for long operations

## File Locations

- `$HOME/vm-personal-provisioning` - This repository (persists across WSL reinstalls via OneDrive)
- `$HOME/Repos` - Main repositories (`kb-deduction-notices-api`, `kb-rcer-pepss-api`)
- `$HOME/Repos/infrastructure` - Infrastructure repos (terraform, CI/CD)
- `$HOME/.aws/config` - AWS SSO profiles (copied from `config/aws-config`)
- `$HOME/.azure_devops_pat` - Azure DevOps PAT (user creates manually, optional)

## Critical Workflows

**Adding new repositories:** Edit [personal_provisioning.sh](../personal_provisioning.sh#L35-50) `git clone` section

**Modifying AWS profiles:** Edit [config/aws-config](../config/aws-config) before testing changes

**Adding shell utilities:** Add functions to [utils/risk_rangers_functions.sh](../utils/risk_rangers_functions.sh), export them

**Changing WSL image location:** Update `IMAGE_PATH` in [get-latest-wsl.sh](../get-latest-wsl.sh)

## Common Pitfalls

- **Running get-latest-wsl.sh from WSL** - Must run from Git Bash on Windows (script detects and exits)
- **Missing SSH keys** - GitHub cloning fails without keys configured and authorized for Kiwibank org
- **Hardcoded paths** - Use `$PROVISIONING_DIR` and `$REPOS` variables, never hardcode
- **Duplicated config** - ZSH config appends; re-running provisioning duplicates entries (add checks)
- **Silent dependency failures** - Always verify tools exist before use (e.g., `command -v jq`)
- **Unset variables** - Use `${VAR:-default}` when variable might not exist

## Testing Changes

1. Test in isolated WSL instance first (script supports clean reinstalls)
2. Verify both initial provisioning AND re-run scenarios
3. Check color output renders correctly in Git Bash and WSL terminals
4. Ensure error messages are visible (use `${RED}` for failures)

See [README.md](../README.md) for user-facing setup instructions and prerequisites.
