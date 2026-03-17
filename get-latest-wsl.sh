#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# Configuration
SHAREPOINT_URL="https://kiwibanknz.sharepoint.com/sites/GRP-Vagrant-Storage/Shared%20Documents/Forms/AllItems.aspx?viewid=7226a014%2D9cda%2D44d2%2Da5c0%2Dc76d0efc4041&as=json&id=%2Fsites%2FGRP%2DVagrant%2DStorage%2FShared%20Documents%2FWSL%2Fkb%2Dubuntu%2Ewsl&parent=%2Fsites%2FGRP%2DVagrant%2DStorage%2FShared%20Documents%2FWSL"
IMAGE_PATH="$HOME/Downloads/kb-ubuntu.wsl"
IMAGE_NAME="kb-ubuntu.wsl"

# Function to get WSL distribution name and clean it
get_kb_distro() {
    wsl.exe --list --quiet | iconv -f UTF-16LE -t UTF-8 | grep -i "kb-ubuntu" | head -1 | tr -d '\r\n' | xargs
}

# Check if running on Windows (Git Bash)
check_running_environment() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "Error: This script must be run from Git Bash on Windows, not from within WSL"
        echo "Please run this script from Git Bash terminal on Windows"
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
        echo "IMAGE FILE IS OLD"
        echo "=========================================="
        echo "Your image file was downloaded on: $file_date"
        echo "This is $file_age_days days old."
        echo ""
        echo "There might be a newer version available on SharePoint."
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
        echo "UPGRADE CONFIRMATION"
        echo "=========================================="
        echo "Existing installation: $existing_distro"
        echo ""
        echo "WARNING: The new installation will overwrite the existing one."
        echo "You will LOSE ALL UNSAVED WORK in WSL."
        echo "All files not in OneDrive or Git will be lost."
        echo ""
        echo "Make sure you have committed and pushed all your code!"
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
}

# Install WSL distribution
install_wsl_distribution() {
    echo ""
    echo "=========================================="
    echo "Installing WSL Distribution"
    echo "=========================================="
    echo "This may take several minutes..."
    echo ""

    if ! wsl.exe --install --from-file "$IMAGE_PATH"; then
        echo ""
        echo "Error: Failed to install distribution"
        exit 1
    fi

    echo ""
    echo "WSL distribution installed successfully!"
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
        echo "Warning: Could not detect the new distribution name"
        echo "Please check 'wsl -l' to see installed distributions"
        exit 1
    fi

    echo ""
    echo "=========================================="
    echo "Setup Completed Successfully!"
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
    echo "KB WSL Setup & Update Script"
    echo "=========================================="

    check_running_environment
    check_image_exists
    confirm_installation
    install_wsl_distribution
    finalize_setup
}

# Run main function
main
