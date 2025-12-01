#!/usr/bin/bash

# fix_docker_credentials - Fixes Docker credentials storage configuration
#
# Usage:
#   fix_docker_credentials
#
# Description:
#   Fixes the Docker credentials storage error by updating ~/.docker/config.json.
#   On macOS, sets credsStore to "osxkeychain". On Linux, removes credsStore
#   to use default file-based storage.
#
# Returns:
#   0 on success, 1 on failure
function fix_docker_credentials() {
    echo "Docker credentials storage error detected. Fixing configuration..."
    local docker_config="$HOME/.docker/config.json"

    # Create .docker directory if it doesn't exist
    mkdir -p "$HOME/.docker"

    # Fix the credsStore configuration
    if [ -f "$docker_config" ]; then
        # Remove credsStore or set it to osxkeychain depending on OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS: use osxkeychain
            jq '.credsStore = "osxkeychain"' "$docker_config" > "${docker_config}.tmp" && mv "${docker_config}.tmp" "$docker_config"
        else
            # Linux: remove credsStore to use default file storage
            jq 'del(.credsStore)' "$docker_config" > "${docker_config}.tmp" && mv "${docker_config}.tmp" "$docker_config"
        fi
    else
        # Create minimal config file
        echo '{}' > "$docker_config"
    fi

    return 0
}

# ecr_docker_login - Performs Docker login to ECR with automatic error handling
#
# Usage:
#   ecr_docker_login <profile> <registry-url>
#
# Parameters:
#   profile: AWS profile to use for authentication
#   registry-url: ECR registry URL to login to
#
# Description:
#   Attempts to login to ECR using AWS credentials. If credentials storage
#   error occurs, automatically fixes the configuration and retries.
#
# Returns:
#   0 on success, 1 on failure
function ecr_docker_login() {
    local profile=$1
    local registry=$2

    if [ -z "$profile" ] || [ -z "$registry" ]; then
        echo "Usage: ecr_docker_login <profile> <registry-url>"
        return 1
    fi

    # Attempt docker login and handle credentials storage error
    local docker_login_output
    if ! docker_login_output=$(aws ecr get-login-password --region ap-southeast-2 --profile "$profile" | docker login --username AWS --password-stdin "$registry" 2>&1); then
        if echo "$docker_login_output" | grep -q "error storing credentials"; then
            fix_docker_credentials

            # Retry docker login
            echo "Retrying docker login..."
            aws ecr get-login-password --region ap-southeast-2 --profile "$profile" | docker login --username AWS --password-stdin "$registry"
        else
            echo "Docker login failed: $docker_login_output"
            return 1
        fi
    fi

    return 0
}

# login_aws - Handles AWS authentication and configuration
#
# Usage:
#   login_aws
#
# Description:
#   This function performs the following:
#   1. Authenticates with cip-nonprod profile:
#      - Performs SSO login if needed
#      - Updates EKS config for atanga cluster
#      - Configures ECR docker login
#   2. Authenticates with ciptooling-prod profile
#   3. Sets up environment variables:
#      - CODEARTIFACT_AUTH_TOKEN for artifact access
#      - PROD_ECR_HOST_NAME for ECR registry
#
# No parameters required
function login_aws() {
    # Check and login to cip-nonprod
    if ! aws sts get-caller-identity --profile "cip-nonprod" >/dev/null 2>&1; then
        aws sso login --profile "cip-nonprod"
        aws eks update-kubeconfig --region ap-southeast-2 --name atanga --profile "cip-nonprod"
        ecr_docker_login "cip-nonprod" "250300400957.dkr.ecr.ap-southeast-2.amazonaws.com"
    fi

    # Check and login to ciptooling-prod
    if ! aws sts get-caller-identity --profile "ciptooling-prod" >/dev/null 2>&1; then
        aws sso login --profile "ciptooling-prod"
    fi

    # Set environment variables
    auth_token=$(aws codeartifact get-authorization-token --region ap-southeast-2 --profile "ciptooling-prod" --domain kb-domain --domain-owner 853871969080 --query authorizationToken --output text)
    export CODEARTIFACT_AUTH_TOKEN="${auth_token}"
}

# configure_azure_devops_pat - Configures Azure DevOps Personal Access Token
#
# Usage:
#   configure_azure_devops_pat [-f|--force]
#
# Parameters:
#   -f, --force: Optional. Force update of PAT even if already configured
#
# Description:
#   This function checks if AZURE_DEVOPS_EXT_PAT is set and prompts the user
#   to enter it if not configured or if force update is requested. It saves
#   the PAT to the environment file and sets it for the current session.
#
# Returns:
#   0 if PAT is configured successfully or already set
#   1 if configuration fails or invalid arguments provided
# shellcheck disable=SC2120
function configure_azure_devops_pat() {
    local force_update=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                force_update=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                echo "Usage: configure_azure_devops_pat [-f|--force]"
                return 1
                ;;
        esac
    done

    # Check if AZURE_DEVOPS_EXT_PAT is set and force update is not requested
    if [ "$force_update" = false ] && [ -n "${AZURE_DEVOPS_EXT_PAT}" ] && [ "${AZURE_DEVOPS_EXT_PAT}" != "ReplaceWithYourPAT" ]; then
        echo "Azure DevOps PAT is already configured. Use -f flag to force update."
        return 0
    fi

    if [ "$force_update" = true ] || [ -z "${AZURE_DEVOPS_EXT_PAT}" ] || [ "${AZURE_DEVOPS_EXT_PAT}" = "ReplaceWithYourPAT" ]; then
        if [ "$force_update" = true ]; then
            echo "Forcing update of Azure DevOps Personal Access Token (PAT)."
        else
            echo "Azure DevOps Personal Access Token (PAT) is not configured."
        fi
        echo "Please enter your Azure DevOps PAT:"
        read -s pat_input

        if [ -z "$pat_input" ]; then
            echo "Error: No PAT provided"
            return 1
        fi

        # Update the secure PAT file in home directory (not in git)
        local pat_file="$HOME/.azure_devops_pat"

        # Create the file with the PAT
        cat > "$pat_file" << EOF
#!/bin/bash
# Sensitive Azure DevOps PAT - DO NOT COMMIT TO GIT
export AZURE_DEVOPS_EXT_PAT="$pat_input"
EOF

        # Ensure the file has appropriate permissions (readable only by owner)
        chmod 600 "$pat_file"

        echo "PAT saved securely to $pat_file"

        # Set the environment variable for current session
        export AZURE_DEVOPS_EXT_PAT="$pat_input"
    fi

    return 0
}

# new_branch - Creates a new git branch based on Azure DevOps work item
#
# Prerequisites:
#   AZURE_DEVOPS_EXT_PAT environment variable must be set with a valid Azure DevOps
#   Personal Access Token to fetch work item details
#
# Usage:
#   new_branch <story-number> [branch-type]
#
# Parameters:
#   story-number: Required. The Azure DevOps work item number
#   branch-type:  Optional. Type of branch to create (default: feature)
#                 Allowed values: feature, bugfix, format, refactoring
#
# Description:
#   This function:
#   1. Fetches work item details from Azure DevOps
#   2. Creates a branch name in format: AB#<number>/<type>-<cleaned-title>
#   3. Stashes any uncommitted changes
#   4. Updates main branch with latest changes
#   5. Creates new branch from updated main
#   6. Restores stashed changes if any
#
# Examples:
#   new_branch 12345              # Creates feature branch for story 12345
#   new_branch 12345 bugfix       # Creates bugfix branch for story 12345
#
# Note:
#   If AZURE_DEVOPS_EXT_PAT is not set, the function will fail to fetch
#   work item details from Azure DevOps
function new_branch() {
    local number=$1

    if [ -z "$number" ]; then
        echo "Usage: new_branch <story-number> [branch-type]"
        return 1
    fi

    # Configure Azure DevOps PAT if needed (without passing branch arguments)
    if ! configure_azure_devops_pat; then
        return 1
    fi

    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: Not in a git repository"
        return 1
    fi

    # Get work item title from Azure DevOps API
    local title
    title=$(az boards work-item show --id "$number" --organization "https://dev.azure.com/Kiwibank" --query "fields" -o json | jq -r '."System.Title"')

    if [ -z "$title" ]; then
        echo "Error: Could not fetch work item title from Azure DevOps"
        return 1
    fi

    # Convert special characters and spaces to dashes
    clean_title=$(echo "$title" | sed 's/[^[:alnum:]]/-/g' | tr -s '-' | sed 's/-$//')

    # Create branch name
    # Set default branch type if not provided
    local branch_type=${2:-feature}

    # Validate branch type
    case $branch_type in
        feature|bugfix|format|refactoring) ;;
        *) echo "Error: Invalid branch type. Use feature, bugfix, format, or refactoring"; return 1;;
    esac

    branch_name="AB#${number}/${branch_type}-${clean_title}"

    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo "Error: Branch '$branch_name' already exists"
        return 1
    fi

    # Check if there are uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo "Stashing uncommitted changes..."
        if ! git stash push -m "Temporary stash before creating new branch"; then
            echo "Error: Failed to stash changes"
            return 1
        fi
        local stashed=true
    fi

    # Checkout main branch first
    if ! git checkout main; then
        # If stashed and checkout fails, pop the stash back
        if [ "$stashed" = true ]; then
            git stash pop
        fi
        echo "Error: Failed to checkout main branch"
        return 1
    fi

    # Pull latest changes from main
    if ! git pull origin main; then
        # If stashed and pull fails, pop the stash back
        if [ "$stashed" = true ]; then
            git checkout - && git stash pop
        fi
        echo "Error: Failed to pull latest changes from main"
        return 1
    fi

    # Create and checkout new branch
    if ! git checkout -b "$branch_name"; then
        # If stashed and branch creation fails, pop the stash back
        if [ "$stashed" = true ]; then
            git checkout - && git stash pop
        fi
        echo "Error: Failed to create branch '$branch_name'"
        return 1
    fi

    # Pop the stash if we stashed changes earlier
    if [ "$stashed" = true ]; then
        echo "Restoring uncommitted changes..."
        if ! git stash pop; then
            echo "Warning: Failed to restore stashed changes. Your changes are still in the stash."
            return 1
        fi
    fi

    echo "Created and switched to branch: $branch_name"
}

# rds_token - Generates an RDS authentication token for Atanga database
#
# Usage:
#   rds_token
#
# Description:
#   Generates an authentication token for connecting to the Atanga PostgreSQL
#   RDS instance in the cip-nonprod environment. The token is displayed and
#   exported as the PG_PASSWORD environment variable for database authentication.
#
# Returns:
#   The authentication token string
function rds_token() {
    local token
    token=$(aws rds generate-db-auth-token --hostname "atanga-postgres-instance.cii0zbi7rvwv.ap-southeast-2.rds.amazonaws.com" --port 5432 --region ap-southeast-2 --username "atanga_readonly" --profile "cip-nonprod")
    echo "$token"
}

# Make functions available in both bash and zsh
if [ -n "$BASH_VERSION" ]; then
    # Bash supports export -f
    export -f fix_docker_credentials
    export -f ecr_docker_login
    export -f login_aws
    export -f configure_azure_devops_pat
    export -f new_branch
    export -f rds_token
elif [ -n "$ZSH_VERSION" ]; then
    # Zsh doesn't need export -f, functions are automatically available
    # when sourced in subshells if defined in .zshrc
    :
fi
