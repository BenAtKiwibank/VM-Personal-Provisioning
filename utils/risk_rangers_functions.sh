#!/bin/bash

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
        aws ecr get-login-password --region ap-southeast-2 --profile "cip-nonprod" | docker login --username AWS --password-stdin 250300400957.dkr.ecr.ap-southeast-2.amazonaws.com
    fi

    # Check and login to ciptooling-prod
    if ! aws sts get-caller-identity --profile "ciptooling-prod" >/dev/null 2>&1; then
        aws sso login --profile "ciptooling-prod"
    fi

    # Set environment variables
    auth_token=$(aws codeartifact get-authorization-token --region ap-southeast-2 --profile "ciptooling-prod" --domain kb-domain --domain-owner 853871969080 --query authorizationToken --output text)
    export CODEARTIFACT_AUTH_TOKEN="${auth_token}"
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
        echo "Usage: create_feature_branch <story-number>"
        return 1
    fi

    # Check if AZURE_DEVOPS_EXT_PAT is set
    if [ -z "${AZURE_DEVOPS_EXT_PAT}" ] || [ "${AZURE_DEVOPS_EXT_PAT}" = "ReplaceWithYourPAT" ]; then
        echo "Error: AZURE_DEVOPS_EXT_PAT environment variable must be set with a valid PAT"
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

export -f login_aws
export -f new_branch