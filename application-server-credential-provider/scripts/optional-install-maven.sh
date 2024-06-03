#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
MAVEN_VERSION=3.9.7
MAVEN_DOWNLOAD_URL=https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
INSTALL_DIR=/opt/maven
PROFILE_SCRIPT=/etc/profile.d/maven.sh

# Ensure the script is run as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Download Maven
echo "Downloading Maven..."
wget -q $MAVEN_DOWNLOAD_URL -O /tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz

# Create installation directory
echo "Installing Maven..."
mkdir -p $INSTALL_DIR

# Extract Maven
tar -xzf /tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz -C $INSTALL_DIR --strip-components=1

# Cleanup
rm /tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz

# Setup environment variables
echo "Setting up environment variables..."
cat <<EOL > $PROFILE_SCRIPT
export MAVEN_HOME=$INSTALL_DIR
export PATH=\$MAVEN_HOME/bin:\$PATH
EOL

# Load the new environment variables
source $PROFILE_SCRIPT

# Verify installation
echo "Verifying Maven installation..."
mvn -version

echo "Maven installation completed successfully."

