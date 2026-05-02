#!/bin/bash
# This script installs Ansible for the local user

set -euo pipefail

#========== Script ===============
FUNCTIONS_FILE="./functions"

if [[ -f "$FUNCTIONS_FILE" ]]; then
    source "$FUNCTIONS_FILE"
else
    echo "Error: Functions file not found at $FUNCTIONS_FILE"
    exit 1
fi

check_if_command_exists python3 
check_if_command_exists pip3

echo "Installing Ansible..."
python3 -m pip install --user ansible

# Ensure local bin is in PATH for the current session
export PATH="$PATH:$HOME/.local/bin"

echo "=========================="
ansible --version
echo "=========================="
echo "Installation complete."
echo "If not already done, please add Ansible to your PATH permanently by pasting the below into your rc file (e.g., ~/.bashrc or ~/.zshrc):"
echo 'export PATH="$PATH:$HOME/.local/bin"'