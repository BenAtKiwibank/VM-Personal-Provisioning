# KB WSL Development Environment Setup

Automation scripts for setting up the KB Ubuntu WSL development environment with AWS SSO, development tools, and git workflow utilities.

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
