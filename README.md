# KB WSL Development Environment Setup

Automation scripts for setting up the KB Ubuntu WSL development environment with AWS SSO, development tools, and git workflow utilities.

## Prerequisites

Before running the setup script, ensure you have:

1. **Windows 10 (version 2004 or higher) or Windows 11**
   - WSL 2 must be installed and configured
   - To install WSL 2, run in PowerShell as Administrator:
     ```powershell
     wsl --install
     ```
   - Set WSL 2 as default:
     ```powershell
     wsl --set-default-version 2
     ```

2. **Git Bash for Windows**
   - Download from KB software centre

3. **Access to Kiwibank SharePoint**
   - Required to download the WSL image

4. **GitHub SSH Keys**
   - Must be configured for your GitHub account
   - Required for automatic repository cloning during provisioning
   
   Generate SSH key:
   ```bash
   ssh-keygen -t ed25519 -C "<YOUR_EMAIL>" -f ~/.ssh/id_ed25519 -N ''
   cat ~/.ssh/id_ed25519.pub
   ```
   
   Then:
   - Copy the public key output
   - Go to GitHub Settings → SSH and GPG keys → New SSH key
   - Paste your key and save
   - **Important:** Authorize the key for Kiwibank organization access
   
   Guide: https://docs.github.com/en/authentication/connecting-to-github-with-ssh

5. **Azure DevOps PAT** (Optional)
   - Required for git workflow utilities
   - Configure in `utils/risk_rangers_env.sh` after installation

## Quick Start

1. **Clone this repository** to your OneDrive:

   ```bash
   git clone <repo-url> "~/OneDrive\ -\ Kiwibank/VM-Personal-Provisioning"
   ```

2. **Open Git Bash** on your Windows PC

3. **Run the setup script:**

   ```bash
   ~/OneDrive\ -\ Kiwibank/VM-Personal-Provisioning/get-latest-wsl.sh
   ```

4. **Follow the instructions** in the script

**Important:** Run this from Git Bash on Windows, not from within WSL.

## How It Works

The setup script will:

1. **Check for WSL image** - Looks for `kb-ubuntu.wsl` in your Downloads folder
2. **Verify age** - If the image is older than 30 days, offers to backup and prompts you to download the latest version
3. **Show existing installations** - Lists any current KB Ubuntu WSL installations
4. **Confirm installation** - Warns about data loss if upgrading an existing installation
5. **Install WSL** - Creates a new WSL distribution from the image file
6. **Auto-provision** - The provisioning script runs automatically on first login to set up your environment

## What's Included

After installation:

- AWS SSO configured profiles
- Development tools (Oh My Zsh, Python, Node, etc.)
- Git workflow utilities

## Repository Structure

- `get-latest-wsl.sh` - Main entry point for WSL installation/upgrade
- `personal_provisioning.sh` - Auto-runs on first login to set up development environment
- `tools/` - Installation and configuration scripts
- `utils/` - Common utility functions and environment configurations
- `aws-config` - AWS SSO profile configuration
