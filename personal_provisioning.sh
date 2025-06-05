#!/bin/bash

echo "Setting up personal provisioning script..."
source $HOME/.bashrc

export PROVISIONING_DIR=$HOME/vm-personal-provisioning
export REPOS=$HOME/Repos

find $PROVISIONING_DIR -name "*.sh" -type f -exec chmod +x {} \;

mkdir -p $HOME/.aws
cp $PROVISIONING_DIR/aws-config  $HOME/.aws/config
chmod 600 $HOME/.aws/config

# install tools
cd $HOME
dotnet tool install --global dotnet-ef
pip install pre-commit

mkdir -p $REPOS
git config --global core.longpaths true
git config --global push.autoSetupRemote true
# make sure your ssh keys are set up in github
cd $REPOS
git clone git@github.com:Kiwibank/kb-deduction-notices-api.git
git clone git@github.com:Kiwibank/kb-rcer-pepss-api.git

# infrasturucture repositories
mkdir -p $REPOS/infrastructure
cd $REPOS/infrastructure
git clone git@github.com:Kiwibank/kb-cicd-infrastructure.git # Config CI/CD pipelines
git clone git@github.com:Kiwibank/terraform-cip-consumers.git # Terraform module for CI/CD consumers
git clone git@github.com:Kiwibank/kb-tf-esp.git # Terraform module for ESP (Evnet Stream Processing) infrastructure

# pre-install pre-commit hooks
cd $REPOS/kb-deduction-notices-api
pre-commit install
pre-commit install --hook-type commit-msg 

cd $REPOS/kb-rcer-pepss-api
pre-commit install
pre-commit install --hook-type commit-msg