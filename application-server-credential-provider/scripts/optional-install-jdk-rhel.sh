#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if Java version is provided as an argument, otherwise use default
JAVA_VERSION=${1:-17}

# Function to check Java version
check_java_version() {
    if command -v java &> /dev/null; then
        JAVA_CURRENT_VERSION=$(java -version 2>&1 | awk -F[\".] 'NR==1{print $2}')
        echo "Detected Java version: $JAVA_CURRENT_VERSION"
        if [ "$JAVA_CURRENT_VERSION" -ge "$JAVA_VERSION" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Check if Java is installed and if it meets the required version
if check_java_version; then
    echo "Java version $(java -version 2>&1 | awk -F[\".] 'NR==1{print $2"."$3}') is already installed."
    java -version
    exit 0
else
    echo "Java is either not installed or the version is less than $JAVA_VERSION. Proceeding with installation."
fi

# Install OpenJDK Development Kit
echo "Installing OpenJDK $JAVA_VERSION..."
sudo yum install -y java-$JAVA_VERSION-openjdk-devel

# Set Java 17 as the default version
echo "Configuring alternatives to set Java $JAVA_VERSION as the default..."
sudo alternatives --install /usr/bin/java java /usr/lib/jvm/java-$JAVA_VERSION-openjdk/bin/java 1
sudo alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-$JAVA_VERSION-openjdk/bin/javac 1
sudo alternatives --set java /usr/lib/jvm/java-$JAVA_VERSION-openjdk/bin/java
sudo alternatives --set javac /usr/lib/jvm/java-$JAVA_VERSION-openjdk/bin/javac

# Verify the installation
if check_java_version; then
    echo "JDK installation successful."
    java -version
    javac -version
    exit 0
else
    echo "Installed Java version is less than $JAVA_VERSION after installation. Something went wrong."
    exit 1
fi

