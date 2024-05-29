#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if Java version is provided as an argument, otherwise use default
JAVA_VERSION=${1:-1.8.0}

# Check if Java is installed
if ! command -v java &> /dev/null; then
    echo "Java is not installed. Please install Java to proceed."
    exit 1
fi

# Check if javac is installed
if command -v javac &> /dev/null; then
    echo "javac is already installed."
    javac -version
    exit 0
fi

# Install OpenJDK Development Kit
sudo yum install -y java-$JAVA_VERSION-openjdk-devel

# Verify the installation
if command -v javac &> /dev/null; then
    echo "JDK installation successful."
    javac -version
else
    echo "JDK installation failed."
    exit 1
fi
