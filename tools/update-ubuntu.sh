#!/bin/bash

# Ubuntu Release Upgrade Script
# Updates Ubuntu to the latest available release version

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}" 
   exit 1
fi

echo -e "${GREEN}=== Ubuntu Release Upgrade Script ===${NC}\n"

# Display current version
echo -e "${YELLOW}Current Ubuntu version:${NC}"
lsb_release -a
echo ""

# Preserve file permissions and ownership during upgrade
echo -e "${YELLOW}Setting upgrade options to preserve file permissions...${NC}"
export DEBIAN_FRONTEND=noninteractive
export UCF_FORCE_CONFFOLD=1
echo 'Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}' > /etc/apt/apt.conf.d/50preserveconfig

# Backup current permission configurations
echo -e "${YELLOW}Backing up permission configurations...${NC}"
BACKUP_DIR="/var/backups/upgrade-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
getfacl -R /etc > "$BACKUP_DIR/etc-permissions.acl" 2>/dev/null || true
getfacl -R /home > "$BACKUP_DIR/home-permissions.acl" 2>/dev/null || true
cp /etc/passwd "$BACKUP_DIR/passwd.bak"
cp /etc/group "$BACKUP_DIR/group.bak"
cp /etc/shadow "$BACKUP_DIR/shadow.bak"
chmod 600 "$BACKUP_DIR/shadow.bak"
echo -e "${GREEN}Permissions backed up to: $BACKUP_DIR${NC}\n"

# Update package lists
echo -e "${YELLOW}Step 1: Updating package lists...${NC}"
apt-get update

# Upgrade all currently installed packages
echo -e "${YELLOW}Step 2: Upgrading currently installed packages...${NC}"
apt-get upgrade -y

# Perform distribution upgrade (handles dependencies)
echo -e "${YELLOW}Step 3: Performing distribution upgrade...${NC}"
apt-get dist-upgrade -y

# Remove unnecessary packages
echo -e "${YELLOW}Step 4: Removing unnecessary packages...${NC}"
apt-get autoremove -y
apt-get autoclean -y

# Install update-manager-core if not present
if ! command -v do-release-upgrade &> /dev/null; then
    echo -e "${YELLOW}Installing update-manager-core...${NC}"
    apt-get install -y update-manager-core
fi

# Check if a new release is available
echo -e "${YELLOW}Step 5: Checking for new Ubuntu releases...${NC}"
RELEASE_CHECK=$(do-release-upgrade -c 2>&1 || true)
echo "$RELEASE_CHECK"

if echo "$RELEASE_CHECK" | grep -q "No new release found"; then
    echo -e "${GREEN}Your system is already running the latest LTS release.${NC}"
    echo -e "${YELLOW}If you want to upgrade to non-LTS releases, run:${NC}"
    echo -e "  sudo do-release-upgrade -d"
else
    echo -e "${YELLOW}Step 6: Starting release upgrade...${NC}"
    echo -e "${RED}WARNING: This will upgrade your Ubuntu release.${NC}"
    echo -e "${RED}Make sure you have backups before proceeding.${NC}"
    echo -e "${YELLOW}The upgrade will start in 10 seconds. Press Ctrl+C to cancel.${NC}"
    sleep 10
    
    # Perform the release upgrade
    # Use -f (frontend) noninteractive for fully automated upgrade
    # Remove -f DistUpgradeViewNonInteractive for interactive mode
    do-release-upgrade -f DistUpgradeViewNonInteractive
fi

# Clean up temporary apt configuration
rm -f /etc/apt/apt.conf.d/50preserveconfig

echo -e "${GREEN}=== Upgrade process completed! ===${NC}"
echo -e "${YELLOW}New Ubuntu version:${NC}"
lsb_release -a
echo ""
echo -e "${GREEN}File permissions and ownership have been preserved.${NC}"
echo -e "${YELLOW}Permission backups stored in: $BACKUP_DIR${NC}\n"
echo -e "${YELLOW}It is recommended to reboot your system now.${NC}"
echo -e "Run: ${GREEN}sudo reboot${NC}"
