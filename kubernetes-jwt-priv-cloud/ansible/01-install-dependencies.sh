#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Ansible on macOS
install_ansible_macos() {
    echo "Installing Ansible on macOS..."
    brew install ansible
}

# Install Ansible on Debian/Ubuntu
install_ansible_debian() {
    echo "Installing Ansible on Debian/Ubuntu..."
    sudo apt update -y
    # התקנה ישירה מה-repositories הרשמיים ללא תלות ב-PPA
    sudo apt install -y software-properties-common python3-pip ansible
}

# Install Ansible on RHEL/CentOS/Fedora
install_ansible_rhel() {
    echo "Installing Ansible on RHEL/CentOS..."
    if command_exists dnf; then
        sudo dnf install -y epel-release || true
        sudo dnf install -y ansible python3-pip
    else
        sudo yum install -y epel-release || true
        sudo yum install -y ansible python3-pip
    fi
}

# Check the OS and install Ansible if not installed
if command_exists ansible; then
    echo "Ansible is already installed."
else
    echo "Ansible is not installed. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists brew; then
            install_ansible_macos
        else
            echo "Error: Homebrew is not installed. Please install Homebrew first."
            exit 1
        fi
    elif [[ -f /etc/debian_version ]]; then
        install_ansible_debian
    elif [[ -f /etc/redhat-release ]]; then
        install_ansible_rhel
    else
        echo "Error: Unsupported OS. Please install Ansible manually."
        exit 1
    fi
fi

# Collection name
COLLECTION="community.general"

# Install collection safely (ansible-galaxy is naturally idempotent)
echo "Ensuring Ansible collection '$COLLECTION' is installed..."
ansible-galaxy collection install "$COLLECTION"