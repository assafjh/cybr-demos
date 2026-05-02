#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Logging setup
LOG_FILE="/var/log/cyberark_cp_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Check if the user is running the script as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Error: This script must be run as root" 
   exit 1
fi

# Variables - Use environment variables or defaults
VAULT_IP="${VAULT_IP:-"10.0.0.1"}"
VAULT_USER="${VAULT_USER:-"prov_user"}"
# Never hardcode the password; provide it via env var before running
VAULT_PASSWORD="${VAULT_PASSWORD:? "Error: VAULT_PASSWORD environment variable is not set."}"

# Locate installer in current or parent directory
INSTALLER_NAME="CyberArk-Credential-Provider-Linux-x86_64.tar.gz"
CP_INSTALLER_PATH=$(find . -name "$INSTALLER_NAME" -print -quit)

# Functions
function check_prerequisites {
    echo "🔍 Checking prerequisites..."
    for cmd in tar curl rpm; do
        if ! command -v $cmd &> /dev/null; then
            echo "❌ Error: $cmd is not installed."
            exit 1
        fi
    done

    if [[ -z "$CP_INSTALLER_PATH" ]]; then
        echo "❌ Error: Installer $INSTALLER_NAME not found in current directory."
        exit 1
    fi
}

function prepare_installation {
    echo "📂 Preparing installation environment..."
    mkdir -p /var/tmp/ascp_install
    tar -xzf "$CP_INSTALLER_PATH" -C /var/tmp/ascp_install
}

function configure_aimparms {
    echo "📝 Configuring installation parameters (aimparms)..."
    # Create the required aimparms file for silent installation
    cat > /var/tmp/ascp_install/aimparms <<EOL
AcceptEULA=Yes
CreateVaultEnvironment=Yes
VaultFilePath=/etc/opt/CARKaim/vault.ini
MainSafe=App_Secrets
AdminUser=$VAULT_USER
AdminPassword=$VAULT_PASSWORD
EOL
}

function install_cp {
    echo "🚀 Installing CyberArk Credential Provider..."
    cd /var/tmp/ascp_install
    
    # Check if we are on RHEL/CentOS/Ubuntu and use the appropriate package manager
    if [[ -f "./CARKaim-latest.x86_64.rpm" ]]; then
        rpm -ivh CARKaim-latest.x86_64.rpm
    else
        # Fallback to provided install script if RPM isn't used
        ./install.sh --accept_eula --skip_interactive
    fi
}

function verify_installation {
    echo "✅ Verifying installation..."
    if systemctl is-active --quiet aimprv; then
        echo "🌟 CyberArk AIM Provider service is running!"
    else
        echo "⚠️ Warning: Service aimprv is not running. Check /var/log/cyberark_cp_install.log"
    fi
}

# Main execution
echo "Starting CyberArk Agent Installation..."
check_prerequisites
prepare_installation
configure_aimparms
install_cp
verify_installation

echo "🏁 Installation process finished. Log: $LOG_FILE"