# Vagrant Personal Provisioning

Automation scripts for setting up development VMs with AWS SSO, development tools, and git workflow utilities.

## Prerequisites

Please follow the [KB Vagrant Development Environment guide](https://kiwibank.atlassian.net/wiki/spaces/PEK/pages/5286232419/Use+KB+Vagrant+Development+Environment) to get Vagrant ready locally.

## Quick Start

### Step 1: Clone the project to OneDrive
```powershell
git clone https://github.com/BenAtKiwibank/risk_rangers_vagrant.git "$env:OneDrive\VM-Personal-Provisioning"
```

### Step 2: Configure Azure DevOps PAT
1. Open `utils/risk_rangers_env.sh`
2. Update your `AZURE_DEVOPS_EXT_PAT` value
3. Follow the [Microsoft guide](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows) to generate a PAT
 

## What's Included

- **AWS SSO Setup**: Auto-configured profiles for `cip-nonprod` and `ciptooling-prod`
- **Development Tools**: Oh My Zsh, Python/Node environments, dotnet tools
- **Git Workflow**: Branch creation from Azure DevOps work items
- **Project Aliases**: Quick navigation to common repositories

## Available Functions

### `login_aws`
Automatically handles AWS authentication and environment setup:
- AWS SSO login for both profiles
- EKS cluster configuration  
- ECR Docker login
- CodeArtifact token setup

**Usage:**
```bash
login_aws
```

### `new_branch <story-number> [branch-type]`
Creates git branches from Azure DevOps work items with automatic title fetching.

**Branch format:** `AB#<number>/<type>-<cleaned-title>`

**Branch types:** `feature` (default), `bugfix`, `format`, `refactoring`

**Examples:**
```bash
new_branch 12345              # Creates: AB#12345/feature-<title>
new_branch 12345 bugfix       # Creates: AB#12345/bugfix-<title>
new_branch 12345 refactoring  # Creates: AB#12345/refactoring-<title>
```

## Setup Requirements

- **Azure DevOps PAT**: Set `AZURE_DEVOPS_EXT_PAT` environment variable
- **GitHub SSH Keys**: Configure SSH keys for repository access
- **AWS SSO Access**: Access to Kiwibank AWS SSO portal
- **Vagrant**: Follow the prerequisite guide above

## Project Navigation

The following aliases are automatically configured for quick navigation:

```bash
repos           # Navigate to ~/Repos
deductionnotice # Navigate to kb-deduction-notices-api project  
pepss           # Navigate to kb-rcer-pepss-api project
```

## AWS Profiles

Two AWS profiles are automatically configured:
- **cip-nonprod**: Development environment (Account: 041371538652)
- **ciptooling-prod**: Production tooling (Account: 778173892410)