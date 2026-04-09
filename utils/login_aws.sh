#!/usr/bin/bash

# AWS authentication and database utilities

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
#   2. Authenticates with cip-nonprod-party profile (shares SSO session with cip-nonprod)
#   3. Authenticates with ciptooling-prod profile
#   4. Sets up environment variables:
#      - CODEARTIFACT_AUTH_TOKEN for artifact access
#      - PROD_ECR_HOST_NAME for ECR registry
#
# No parameters required
function login_aws() {
    # Check and login to cip-nonprod
    if ! aws sts get-caller-identity --profile "cip-nonprod" >/dev/null 2>&1; then
        aws sso login --profile "cip-nonprod"
        aws eks update-kubeconfig --region ap-southeast-2 --name atanga --profile "cip-nonprod"
        aws eks update-kubeconfig --region ap-southeast-2 --name party --profile "cip-nonprod-party"
        ecr_docker_login "cip-nonprod" "250300400957.dkr.ecr.ap-southeast-2.amazonaws.com"
    fi

    # Check and login to cip-nonprod-party (shares SSO session with cip-nonprod)
    if ! aws sts get-caller-identity --profile "cip-nonprod-party" >/dev/null 2>&1; then
        aws sso login --profile "cip-nonprod-party"
    fi

    # Check and login to ciptooling-prod
    if ! aws sts get-caller-identity --profile "ciptooling-prod" >/dev/null 2>&1; then
        aws sso login --profile "ciptooling-prod"
    fi

    # Set environment variables
    auth_token=$(aws codeartifact get-authorization-token --region ap-southeast-2 --profile "ciptooling-prod" --domain kb-domain --domain-owner 853871969080 --query authorizationToken --output text)
    export CODEARTIFACT_AUTH_TOKEN="${auth_token}"
}

# Make functions available in both bash and zsh
if [ -n "$BASH_VERSION" ]; then
    export -f login_aws
elif [ -n "$ZSH_VERSION" ]; then
    # Zsh doesn't need export -f, functions are automatically available
    :
fi
