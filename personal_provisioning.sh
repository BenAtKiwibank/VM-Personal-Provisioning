#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

echo "Setting up personal provisioning script..."

export PROVISIONING_DIR=$HOME/vm-personal-provisioning
export REPOS=$HOME/Repos

find "$PROVISIONING_DIR" -name "*.sh" -type f -exec chmod +x {} \;

# remove unnecessary software
sudo "$PROVISIONING_DIR"/tools/remove_software.sh

# trun off swap to save disk space
sudo swapoff -a

# configure aws
mkdir -p "$HOME"/.aws
cp "$PROVISIONING_DIR"/config/aws-config  "$HOME"/.aws/config
chmod 600 "$HOME"/.aws/config

# install/update tools
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean

# Install pre-commit using pipx (recommended for Python CLI tools)
# Install wslu for WSL-Windows browser integration (provides wslview command)
sudo apt install -y pipx wslu
pipx install pre-commit
pipx ensurepath
# Add pipx binaries to PATH for the current session
export PATH="$HOME/.local/bin:$PATH"

# Install Azure DevOps extension for Azure CLI
# SSL verification must be disabled for corporate environments with SSL inspection
if command -v az >/dev/null 2>&1; then
    echo "Installing Azure DevOps extension for Azure CLI..."
    export PYTHONHTTPSVERIFY=0
    export AZURE_CLI_DISABLE_CONNECTION_VERIFICATION=1
    az extension add --name azure-devops || echo "Warning: Failed to install azure-devops extension. You can install it manually later."
else
    echo "Azure CLI not found. Skipping azure-devops extension installation."
    echo "Install Azure CLI first if you need Azure DevOps integration."
fi

# Clear dotnet tool cache and install dotnet-ef
sudo dotnet workload update
dotnet nuget locals all --clear
dotnet tool install --global dotnet-ef --version 9.0.0

# initial repositories
mkdir -p "$REPOS"
git config --global core.longpaths true
git config --global push.autoSetupRemote true
# make sure your ssh keys are set up in github
cd "$REPOS"
git clone git@github.com:Kiwibank/kb-deduction-notices-api.git
git clone git@github.com:Kiwibank/kb-rcer-pepss-api.git
git clone git@github.com:Kiwibank/kb-party-api.git

# infrasturucture repositories
mkdir -p "$REPOS"/infrastructure
cd "$REPOS"/infrastructure
git clone git@github.com:Kiwibank/kb-cicd-infrastructure.git # Config CI/CD pipelines
git clone git@github.com:Kiwibank/terraform-cip-consumers.git # Terraform module for CI/CD consumers
git clone git@github.com:Kiwibank/kb-tf-esp.git # Terraform module for ESP (Evnet Stream Processing) infrastructure

# pre-install pre-commit hooks
cd "$REPOS"/kb-deduction-notices-api
pre-commit install
pre-commit install --hook-type commit-msg
pre-commit install --hook-type pre-push

cd "$REPOS"/kb-rcer-pepss-api
pre-commit install
pre-commit install --hook-type commit-msg
pre-commit install --hook-type pre-push

cd "$REPOS"/kb-party-api
pre-commit install --hook-type commit-msg

# install oh-my-zsh and apply custom configuration
"$PROVISIONING_DIR"/tools/install-oh-my-zsh.sh

