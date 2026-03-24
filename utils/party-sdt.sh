#!/usr/bin/env bash

# party-sdt - Authenticates with Kerberos for Party SDT database access
#
# Usage:
#   party-sdt [sit|qas]
#
# Parameters:
#   environment: Optional. Target environment - 'sit' or 'qas' (default: sit)
#
# Description:
#   Fetches Kerberos authentication credentials from AWS Secrets Manager and
#   authenticates with the party SDT database. The function:
#   1. Displays the target database server and database name
#   2. Fetches the principal from AWS Secrets Manager (profile: ciptooling-prod-party)
#   3. Sets environment variables for the credentials
#   4. Runs kinit to authenticate
#   5. Shows current Kerberos tickets
#
# Environment Variables Set:
#   KERBEROS_PRINCIPAL - The full Kerberos principal (username@realm)
#   KERBEROS_REALM - The Kerberos realm
#   KERBEROS_ENV - The target environment (SIT or QAS)
#   SDT_SERVER - The SDT database server
#   SDT_DATABASE - The SDT database name
#
# Prerequisites:
#   - AWS CLI configured with ciptooling-prod-party profile
#   - Valid AWS SSO session
#   - kinit and klist commands available
#
# Examples:
#   party-sdt         # Authenticates to SIT (default)
#   party-sdt sit     # Authenticates to SIT
#   party-sdt qas     # Authenticates to QAS (rehearse)
#
# Returns:
#   0 on success, 1 on failure
function party-sdt() {
    # Parse environment parameter (default to sit)
    local env="${1:-sit}"
    env=$(echo "$env" | tr '[:upper:]' '[:lower:]')  # Convert to lowercase

    # Validate environment
    if [[ ! "$env" =~ ^(sit|qas)$ ]]; then
        echo "Error: Invalid environment '$env'. Use 'sit' or 'qas'"
        echo "Usage: party-sdt [sit|qas]"
        return 1
    fi

    # Colors for output
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[1;34m'
    local NC='\033[0m'

    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Party DB Kerberos Authentication     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""

    # Set realm and database configuration based on environment
    local realm
    local server
    local database="ServicelayerDataTier"
    local principal_secret_id
    local password_secret_id

    case "$env" in
        sit)
            realm="CORP.BANK.SIT.KIWIBANK.INTERNAL"
            server="SITCFC-Listener.corp.bank.sit.kiwibank.internal,50530"
            principal_secret_id="/party/apis/party/nonprod/kerberos-auth-principal"
            password_secret_id="/party/apis/party/nonprod/kerberos-auth-password"
            ;;
        qas)
            realm="CORP.BANK.QAS.KIWIBANK.INTERNAL"
            server="SQLCFC-QAS.corp.bank.sit.kiwibank.internal,50532"
            principal_secret_id="/party/apis/party/nonprod/rehearse/kerberos-auth-principal"
            password_secret_id="/party/apis/party/nonprod/rehearse/kerberos-auth-password"
            ;;
    esac

    local env_upper=$(echo "$env" | tr '[:lower:]' '[:upper:]')

    echo -e "${GREEN}[INFO]${NC} Target environment: ${env_upper}"
    echo -e "${GREEN}[INFO]${NC} Database server: ${server}"
    echo -e "${GREEN}[INFO]${NC} Database name: ${database}"
    echo -e "${GREEN}[INFO]${NC} Kerberos realm: ${realm}"
    echo ""

    # Fetch principal from AWS Secrets Manager
    echo -e "${GREEN}[INFO]${NC} Fetching Kerberos credentials from AWS Secrets Manager..."

    local principal
    if ! principal=$(aws secretsmanager get-secret-value \
        --secret-id "$principal_secret_id" \
        --query SecretString \
        --output text \
        --profile ciptooling-prod-party 2>&1); then
        echo -e "${RED}[ERROR]${NC} Failed to fetch principal from AWS Secrets Manager"
        echo -e "${YELLOW}Hint:${NC} Make sure you're logged in: aws sso login --profile ciptooling-prod-party"
        return 1
    fi

    # Trim whitespace from principal
    principal=$(echo "$principal" | xargs)

    local password
    if ! password=$(aws secretsmanager get-secret-value \
        --secret-id "$password_secret_id" \
        --query SecretString \
        --output text \
        --profile ciptooling-prod-party 2>&1); then
        echo -e "${RED}[ERROR]${NC} Failed to fetch password from AWS Secrets Manager"
        echo -e "${YELLOW}Hint:${NC} Make sure you're logged in: aws sso login --profile ciptooling-prod-party"
        return 1
    fi

    # Trim whitespace from password
    password=$(echo "$password" | xargs)

    # Build full principal - check if realm is already included
    local full_principal
    if [[ "$principal" == *"@"* ]]; then
        # Principal already contains realm
        full_principal="$principal"
    else
        # Append realm to principal
        full_principal="${principal}@${realm}"
    fi

    # Export environment variables
    export KERBEROS_PRINCIPAL="$full_principal"
    export KERBEROS_REALM="${realm}"
    export KERBEROS_ENV="${env_upper}"
    export SDT_SERVER="${server}"
    export SDT_DATABASE="${database}"

    echo -e "${GREEN}[INFO]${NC} Principal: ${KERBEROS_PRINCIPAL}"
    echo ""

    # Authenticate with Kerberos
    echo -e "${GREEN}[INFO]${NC} Authenticating with Kerberos..."

    if echo "$password" | kinit "$KERBEROS_PRINCIPAL"; then
        echo ""
        echo -e "${GREEN}[INFO]${NC} ✓ Authentication successful!"
        echo ""
        echo -e "${GREEN}[INFO]${NC} Current Kerberos tickets:"
        klist
        echo ""
        echo -e "${GREEN}[INFO]${NC} You can now connect to ${database} on ${server}"
        echo -e "${GREEN}[INFO]${NC} Ticket will expire in 24 hours. Run party-sdt again to renew."
        return 0
    else
        echo ""
        echo -e "${RED}[ERROR]${NC} ✗ Authentication failed!"
        return 1
    fi
}

# Make function available in both bash and zsh
if [ -n "$BASH_VERSION" ]; then
    export -f party-sdt
elif [ -n "$ZSH_VERSION" ]; then
    # Zsh doesn't need export -f
    :
fi
