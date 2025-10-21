#!/bin/bash

# Personal Software Removal Script
# This script removes software that is not needed 

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

snap remove datagrip
snap remove goland
snap remove intellij-idea-community
snap remove intellij-idea-ultimate
snap remove postman
snap remove powershell
snap remove pycharm-professional
snap remove rider