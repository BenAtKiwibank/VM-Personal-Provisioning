#!/usr/bin/bash

# RDS authentication utilities

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
    export -f rds_token
elif [ -n "$ZSH_VERSION" ]; then
    # Zsh doesn't need export -f, functions are automatically available
    :
fi
