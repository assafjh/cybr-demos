#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if the user is running the script as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Variables (adjust these paths and variables as needed)
CP_INSTALLER_PATH="/path/to/CyberArk-Credential-Provider-Linux-x86_64.tar.gz"
INSTALL_DIR="/opt/CARKaim"
LOG_FILE="/var/log/cyberark_cp_install.log"
VAULT_IP="your_vault_ip"
VAULT_PORT="your_vault_port"
VAULT_USERNAME="your_vault_username"
VAULT_PASSWORD="your_vault_password"

# Functions
function check_prerequisites {
    echo "Checking prerequisites..."
    # Check if necessary commands are available
    for cmd in tar curl; do
        if ! command -v $cmd &> /dev/null; then
            echo "Error: $cmd is not installed. Please install it and try again."
            exit 1
        fi
    done
}

function create_directories {
    echo "Creating necessary directories..."
    mkdir -p /var/opt/CARKaim
    mkdir -p /etc/opt/CARKaim
    mkdir -p /opt/CA
    chmod 755 /var/opt/CARKaim
    chmod 755 /etc/opt/CARKaim
    chmod 755 /opt/CA
}

function set_permissions {
    echo "Setting permissions..."
    chown root:root /var/opt/CARKaim
    chown root:root /etc/opt/CARKaim
    chown root:root /opt/CA
}

function extract_installer {
    echo "Extracting installer..."
    tar -xzf "$CP_INSTALLER_PATH" -C /tmp
}

function install_cp {
    echo "Installing CyberArk Credential Provider..."
    /tmp/CyberArk-Credential-Provider-Install/install.sh --install_dir "$INSTALL_DIR" --accept_eula --skip_interactive

    echo "Installation complete."
}

function configure_cp {
    echo "Configuring CyberArk Credential Provider..."

    # Create and configure dbparm.ini
    cat > /etc/opt/CARKaim/dbparm.ini <<EOL
    Address=$VAULT_IP
    Port=$VAULT_PORT
    UserName=$VAULT_USERNAME
    Password=$VAULT_PASSWORD
EOL

    chmod 600 /etc/opt/CARKaim/dbparm.ini
    chown root:root /etc/opt/CARKaim/dbparm.ini

    echo "Configuration complete."
}

# Main script execution
{
    check_prerequisites
    create_directories
    set_permissions
    extract_installer
    install_cp
    configure_cp
} | tee -a "$LOG_FILE"

echo "Installation log saved to $LOG_FILE"
