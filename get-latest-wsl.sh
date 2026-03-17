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
        echo "Save it as: $IMAGE_PATH"
        echo ""
        echo "Then run this script again."
        exit 1
    fi

    IMAGE_SIZE=$(du -h "$IMAGE_PATH" | cut -f1)
    echo "Found WSL image: $IMAGE_NAME (Size: $IMAGE_SIZE)"
}

# Check if file was downloaded today
check_file_version() {
    local file_date today
    file_date=$(date -r "$IMAGE_PATH" +%Y-%m-%d)
    today=$(date +%Y-%m-%d)

    if [ "$file_date" != "$today" ]; then
        echo ""
        echo "=========================================="
        echo "FILE VERSION CHECK"
        echo "=========================================="
        echo "Your downloaded file was created on: $file_date"
        echo ""
        echo "Please check SharePoint for the latest version:"
        echo "$SHAREPOINT_URL"
        echo ""
        echo "If you want to download the latest version:"
        echo "  1. Download from SharePoint"
        echo "  2. Run this script again"
        echo ""
        read -r -p "Continue with current file? (yes/no): " continue_install

        if [ "$continue_install" != "yes" ]; then
            echo ""
            echo "Installation cancelled."
            exit 0
        fi
    fi
}

# Check if any kb-ubuntu distribution already exists
check_existing_installation() {
    echo ""
    echo "Current WSL distributions:"
    wsl.exe --list --verbose

    local existing_distro
    existing_distro=$(get_kb_distro)

    if [ -n "$existing_distro" ]; then
        echo ""
        echo "=========================================="
        echo "EXISTING INSTALLATION DETECTED"
        echo "=========================================="
        echo "Distribution '$existing_distro' already exists."
        echo ""
        echo "WARNING: Continuing will install a new instance."
        echo "You will LOSE ALL UNSAVED WORK in the existing instance."
        echo "All files not in OneDrive or Git will be lost."
        echo ""
        echo "Make sure you have committed and pushed all your code!"
        echo ""
        read -r -p "Type 'yes' to continue: " confirmation

        if [ "$confirmation" != "yes" ]; then
            echo ""
            echo "Installation cancelled."
            exit 0
        fi
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
    check_file_version
    check_existing_installation
    install_wsl_distribution
    finalize_setup
}

# Run main function
main
