#!/usr/bin/bash

# Docker and ECR authentication utilities

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

# Make functions available in both bash and zsh
if [ -n "$BASH_VERSION" ]; then
    export -f fix_docker_credentials
    export -f ecr_docker_login
elif [ -n "$ZSH_VERSION" ]; then
    # Zsh doesn't need export -f, functions are automatically available
    :
fi
