#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# Colors for better visibility
RED='\033[1;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Configuration
SHAREPOINT_URL="https://kiwibanknz.sharepoint.com/sites/GRP-Vagrant-Storage/Shared%20Documents/Forms/AllItems.aspx?viewid=7226a014%2D9cda%2D44d2%2Da5c0%2Dc76d0efc4041&as=json&id=%2Fsites%2FGRP%2DVagrant%2DStorage%2FShared%20Documents%2FWSL%2Fkb%2Dubuntu%2Ewsl&parent=%2Fsites%2FGRP%2DVagrant%2DStorage%2FShared%20Documents%2FWSL"
IMAGE_NAME="kb-ubuntu.wsl"
IMAGE_PATH="$HOME/Downloads/$IMAGE_NAME"

# Function to get WSL distribution name and clean it
get_kb_distro() {
    wsl.exe --list --quiet | iconv -f UTF-16LE -t UTF-8 | grep -i "kb-ubuntu" | head -1 | tr -d '\r\n' | xargs
}

# Check if WSL 2 is installed and available
check_wsl2_available() {
    echo ""
    echo "Checking WSL installation..."

    if ! command -v wsl.exe &> /dev/null; then
        echo -e "${RED}Error: WSL is not installed${NC}"
        echo ""
        echo "Please install WSL 2 first:"
        echo "https://docs.microsoft.com/en-us/windows/wsl/install"
        echo ""
        echo "Run in PowerShell as Administrator:"
        echo "  wsl --install"
        exit 1
    fi

    # Check if WSL 2 is available
    local wsl_status
    wsl_status=$(wsl.exe --status 2>&1 || echo "")

    if ! echo "$wsl_status" | grep -q "Default Version: 2"; then
        echo -e "${YELLOW}Warning: WSL 2 is not set as the default version${NC}"
        echo ""
        echo "To set WSL 2 as default, run in PowerShell as Administrator:"
        echo "  wsl --set-default-version 2"
        echo ""
        read -r -p "Continue anyway? (yes/no): " continue_wsl1

        if [ "$continue_wsl1" != "yes" ]; then
            echo ""
            echo "Installation cancelled."
            exit 0
        fi
    else
        echo -e "${GREEN}WSL 2 is installed and configured${NC}"
    fi
}

# Check if running on Windows (Git Bash)
check_running_environment() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo -e "${RED}Error: This script must be run from Git Bash on Windows, not from within WSL${NC}"
        echo -e "${YELLOW}Please run this script from Git Bash terminal on Windows${NC}"
        exit 1
    fi
}

# Check if the WSL image exists in Downloads
check_image_exists() {
    echo ""
    echo "Checking for WSL image: $IMAGE_PATH"

    if [ ! -f "$IMAGE_PATH" ]; then
        echo ""
        echo "=========================================="
        echo "WSL IMAGE NOT FOUND"
        echo "=========================================="
        echo "Please download the WSL image from SharePoint:"
        echo ""
        echo "$SHAREPOINT_URL"
        echo ""
        echo "Save it to your Downloads folder as: $IMAGE_NAME"
        echo ""
        echo "Then run this script again."
        exit 1
    fi

    IMAGE_SIZE=$(du -h "$IMAGE_PATH" | cut -f1)
    echo "Found WSL image: $IMAGE_NAME (Size: $IMAGE_SIZE)"

    # Check if file is older than 30 days
    local file_age_days current_time file_time
    current_time=$(date +%s)
    file_time=$(date -r "$IMAGE_PATH" +%s)
    file_age_days=$(( (current_time - file_time) / 86400 ))

    if [ "$file_age_days" -gt 30 ]; then
        local file_date
        file_date=$(date -r "$IMAGE_PATH" +%Y-%m-%d)

        echo ""
        echo "=========================================="
        echo -e "${YELLOW}IMAGE FILE IS OLD${NC}"
        echo "=========================================="
        echo "Your image file was downloaded on: $file_date"
        echo "This is $file_age_days days old."
        echo ""
        echo -e "${YELLOW}There might be a newer version available on SharePoint.${NC}"
        echo ""
        read -r -p "Would you like to download the latest version? (yes/no): " download_new

        if [ "$download_new" = "yes" ]; then
            # Backup old file with timestamp
            local backup_name
            backup_name="${IMAGE_PATH%.wsl}_backup_$(date +%Y%m%d_%H%M%S).wsl"

            echo ""
            echo "Backing up old file to: $backup_name"
            mv "$IMAGE_PATH" "$backup_name"

            echo ""
            echo "Please download the latest image from SharePoint:"
            echo "$SHAREPOINT_URL"
            echo ""
            echo "Save it to your Downloads folder as: $IMAGE_NAME"
            echo ""
            echo "Then run this script again."
            exit 0
        fi

        echo ""
        echo "Continuing with existing file..."
    fi
}

# Confirm installation/upgrade with user
# Confirm installation/upgrade with user
confirm_installation() {
    echo ""
    echo "Current WSL distributions:"
    wsl.exe --list --verbose

    local existing_distro
    existing_distro=$(get_kb_distro)

    echo ""
    echo "=========================================="
    if [ -n "$existing_distro" ]; then
        echo -e "${YELLOW}UPGRADE CONFIRMATION${NC}"
        echo "=========================================="
        echo "Existing installation: $existing_distro"
        echo ""
        echo -e "${RED}WARNING: The new installation will overwrite the existing one.${NC}"
        echo -e "${RED}You will LOSE ALL UNSAVED WORK in WSL.${NC}"
        echo -e "${RED}All files not in OneDrive or Git will be lost.${NC}"
        echo ""
        echo -e "${YELLOW}Make sure you have committed and pushed all your code!${NC}"
    else
        echo "INSTALLATION CONFIRMATION"
        echo "=========================================="
        echo "No existing KB Ubuntu installation found."
        echo ""
        echo "Ready to install new WSL distribution."
    fi
    echo ""
    read -r -p "Continue with installation? (yes/no): " confirmation

    if [ "$confirmation" != "yes" ]; then
        echo ""
        echo "Installation cancelled."
        exit 0
    fi

    # Unregister existing distribution if it exists
    if [ -n "$existing_distro" ]; then
        echo ""
        echo "Unregistering existing distribution: $existing_distro"
        if ! wsl.exe --unregister "$existing_distro"; then
            echo ""
            echo -e "${RED}Error: Failed to unregister existing distribution${NC}"
            exit 1
        fi
        echo -e "${GREEN}Successfully unregistered $existing_distro${NC}"
    fi
}

# Install WSL distribution
install_wsl_distribution() {
    echo ""
    echo "=========================================="
    echo -e "${BLUE}Installing WSL Distribution${NC}"
    echo "=========================================="
    echo "This may take several minutes..."
    echo ""

    if ! wsl.exe --install --from-file "$IMAGE_PATH"; then
        echo ""
        echo -e "${RED}Error: Failed to install distribution${NC}"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}WSL distribution installed successfully!${NC}"
    echo ""
    echo "Current WSL distributions:"
    wsl.exe --list --verbose
}

# Finalize setup
finalize_setup() {
    local new_distro
    new_distro=$(get_kb_distro)

    if [ -z "$new_distro" ]; then
        echo ""
        echo -e "${YELLOW}Warning: Could not detect the new distribution name${NC}"
        echo "Please check 'wsl -l' to see installed distributions"
        exit 1
    fi

    echo ""
    echo "=========================================="
    echo -e "${GREEN}Setup Completed Successfully!${NC}"
    echo "=========================================="
    echo "Distribution installed: $new_distro"
    echo ""
    echo "The provisioning script will run automatically on first login."
    echo ""
    echo "To access your WSL environment:"
    echo ""
    echo "  Option 1: Terminal"
    echo "    wsl -d $new_distro"
    echo ""
    echo "  Option 2: VS Code"
    echo "    Install extension: ms-vscode-remote.remote-wsl"
    echo "    Then connect to WSL from VS Code"
    echo ""
}

# Main execution
main() {
    echo "=========================================="
    echo -e "${BLUE}KB WSL Setup & Update Script${NC}"
    echo "=========================================="

    check_wsl2_available
    check_running_environment
    check_image_exists
    confirm_installation
    install_wsl_distribution
    finalize_setup
}

# Run main function
main
