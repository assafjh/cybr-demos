#!/bin/bash

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Ansible on macOS
install_ansible_macos() {
    echo "Installing Ansible on macOS..."
    brew install ansible
    pip3 install xkcdpass
}

# Install Ansible on Debian/Ubuntu
install_ansible_debian() {
    echo "Installing Ansible on Debian/Ubuntu..."
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt install -y ansible
    sudo apt install -y python3-pip
    pip3 install xkcdpass
}

# Install Ansible on RHEL/CentOS
install_ansible_rhel() {
    echo "Installing Ansible on RHEL/CentOS..."
    sudo yum install -y epel-release
    sudo yum install -y ansible
    sudo yum install -y python3-pip
    pip3 install xkcdpass
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
            echo "Homebrew is not installed. Please install Homebrew first."
            exit 1
        fi
    elif [[ -f /etc/debian_version ]]; then
        install_ansible_debian
    elif [[ -f /etc/redhat-release ]]; then
        install_ansible_rhel
    else
        echo "Unsupported OS. Please install Ansible manually."
        exit 1
    fi
fi

# Function to check if a collection is installed
is_collection_installed() {
    ansible-galaxy collection list "$1" | grep -q "$1"
}

# Collection name
COLLECTION="community.general"

# Check if the collection is installed
if is_collection_installed "$COLLECTION"; then
    echo "Collection $COLLECTION is already installed."
else
    echo "Collection $COLLECTION is not installed. Installing..."
    ansible-galaxy collection install "$COLLECTION"
fi
