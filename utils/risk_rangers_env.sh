#!/bin/bash

# Source sensitive Azure DevOps PAT from home directory (not in git)
if [ -f "$HOME/.azure_devops_pat" ]; then
    source "$HOME/.azure_devops_pat"
fi

export AWS_REGION=ap-southeast-2
export PROD_ECR_HOST_NAME="250300400957.dkr.ecr.ap-southeast-2.amazonaws.com"
