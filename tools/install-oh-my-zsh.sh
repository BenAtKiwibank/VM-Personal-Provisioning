#!/bin/bash

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "oh-my-zsh installed successfully!"
    
    ZSH_CONFIG_FILE="$HOME/vm-personal-provisioning/tools/zsh_config.content"
    if [ -f "$ZSH_CONFIG_FILE" ]; then
        echo "Applying custom zsh configuration..."
        cat "$ZSH_CONFIG_FILE" >> ~/.zshrc
        source ~/.zshrc
        echo "Custom zsh configuration applied!"
    else
        echo "Error: ZSH configuration file not found at $ZSH_CONFIG_FILE"
        exit 1
    fi
else
    echo "oh-my-zsh is already installed, skipping installation."
fi