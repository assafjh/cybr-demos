#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# Using a stable Tomcat 10.1.x version for maximum compatibility with Jakarta EE 10
TOMCAT_VERSION=${1:-"10.1.20"} 
INSTALL_DIR="$SCRIPT_DIR/tomcat"
TOMCAT_PORT=${2:-8081} 

# Functions
function check_java_version() {
    if command -v java &> /dev/null; then
        JAVA_CURRENT_VERSION=$(java -version 2>&1 | awk -F[\".] 'NR==1{print $2}')
        echo "Detected Java version: $JAVA_CURRENT_VERSION"
        # Using 17 as baseline for modern Jakarta EE
        if [ "$JAVA_CURRENT_VERSION" -ge 17 ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

function download_tomcat() {
    local version=$1
    local major_version=$(echo $version | cut -d. -f1)
    # Using the archive URL as it's more stable for specific versions
    local url="https://archive.apache.org/dist/tomcat/tomcat-$major_version/v$version/bin/apache-tomcat-$version.tar.gz"
    
    echo "Downloading Tomcat version $version from $url..."
    wget -q --show-progress $url -O /tmp/apache-tomcat-$version.tar.gz
}

function install_tomcat() {
    local version=$1
    local install_dir=$2
    
    echo "Installing Tomcat into $install_dir..."
    rm -rf "$install_dir" # Clean previous install if exists
    mkdir -p "$install_dir"
    tar -xzf /tmp/apache-tomcat-$version.tar.gz -C "$install_dir" --strip-components=1
    chmod +x "$install_dir"/bin/*.sh
}

function configure_ascp_sdk() {
    echo "🔗 Linking CyberArk ASCP SDK to Tomcat..."
    # The ASCP JDBC Driver/Factory must be in Tomcat's common lib to be visible to JNDI
    ASCP_JDBC_JAR="/opt/CARKaim/sdk/javajdbc/CyberArk.jdbc.VariableFactory.jar"
    
    if [ -f "$ASCP_JDBC_JAR" ]; then
        ln -sf "$ASCP_JDBC_JAR" "$INSTALL_DIR/lib/"
        echo "✅ CyberArk JDBC Factory linked successfully."
    else
        echo "⚠️  Warning: CyberArk JDBC Factory not found at $ASCP_JDBC_JAR."
        echo "   Make sure Script 01 (Agent Install) was successful."
    fi
}

# Main Execution Flow
if ! check_java_version; then
    echo "❌ Error: Java 17 or higher is required."
    exit 1
fi

download_tomcat "$TOMCAT_VERSION"
install_tomcat "$TOMCAT_VERSION" "$INSTALL_DIR"
configure_ascp_sdk
# (The rest of your configuration functions: set_java_home, configure_tomcat, etc.)