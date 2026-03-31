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

# rds_token - Generates an RDS authentication token for database access
#
# Usage:
#   rds_token [--party]
#
# Parameters:
#   --party: Optional. Generate token for party database using CIPUser_party role
#
# Description:
#   Generates an authentication token for connecting to PostgreSQL RDS instances
#   in the cip-nonprod environment.
#
#   Default (no flags): Connects to Atanga database using CIPUser_pekaraurakauapis role
#   - Hostname: atanga-postgres-instance.cii0zbi7rvwv.ap-southeast-2.rds.amazonaws.com
#   - Username: atanga_readonly
#   - Profile: cip-nonprod
#
#   With --party flag: Connects to Party database using CIPUser_party role
#   - Hostname: party-postgres-instance.cii0zbi7rvwv.ap-southeast-2.rds.amazonaws.com
#   - Username: party_readonly
#   - Profile: cip-nonprod-party
#
# Returns:
#   The authentication token string
function rds_token() {
    local hostname="atanga-postgres-instance.cii0zbi7rvwv.ap-southeast-2.rds.amazonaws.com"
    local username="atanga_readonly"
    local profile="cip-nonprod"

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --party)
                hostname="party-postgres-instance.cii0zbi7rvwv.ap-southeast-2.rds.amazonaws.com"
                username="party_readonly"
                profile="cip-nonprod-party"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                echo "Usage: rds_token [--party]"
                return 1
                ;;
        esac
    done

    # Display connection information
    echo "Generating RDS token for:"
    echo "  Hostname: $hostname"
    echo "  Port: 5432"
    echo "  Username: $username"
    echo "  Profile: $profile"
    echo "  Region: ap-southeast-2"
    echo ""

    local token
    token=$(aws rds generate-db-auth-token --hostname "$hostname" --port 5432 --region ap-southeast-2 --username "$username" --profile "$profile")
    echo "$token"
}

# Make functions available in both bash and zsh
if [ -n "$BASH_VERSION" ]; then
    export -f login_aws
    export -f rds_token
elif [ -n "$ZSH_VERSION" ]; then
    # Zsh doesn't need export -f, functions are automatically available
    :
fi
