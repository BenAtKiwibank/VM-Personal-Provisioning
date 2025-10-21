#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

echo "Setting up personal provisioning script..."

export PROVISIONING_DIR=$HOME/vm-personal-provisioning
export REPOS=$HOME/Repos

find $PROVISIONING_DIR -name "*.sh" -type f -exec chmod +x {} \;

# trun off swap to save disk space
sudo swapoff -a

# configure aws
mkdir -p $HOME/.aws
cp $PROVISIONING_DIR/aws-config  $HOME/.aws/config
chmod 600 $HOME/.aws/config

# install/update tools
sudo apt update && sudo apt upgrade -y
if ! dpkg -l | grep -q python3; then
    sudo apt install -y python3 python3-pip
else
    echo "Python3 is already installed"
fi
sudo apt autoremove -y
sudo apt autoclean

pip3 install pre-commit
dotnet tool install --global dotnet-ef

# initial repositories
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