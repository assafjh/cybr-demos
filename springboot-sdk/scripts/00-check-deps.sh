#!/bin/bash

# Stop the script if any command fails
set -e

echo "Checking dependencies..."

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &>/dev/null; then
        return 1
    else
        return 0
    fi
}

# Check Java version
check_java() {
    if check_command java; then
        JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d. -f1)
        if [[ "$JAVA_VERSION" -ge 17 ]]; then
            echo "Java 17 or higher is installed."
            return
        fi
    fi
    echo "Java 17 is not installed or outdated. Installing Java 17..."
    install_java
}

# Check Gradle
check_gradle() {
    if check_command gradle; then
        echo "Gradle is already installed."
        return
    fi
    echo "Gradle is not installed. Installing Gradle..."
    install_gradle
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt &>/dev/null; then
            OS="ubuntu"
        elif command -v yum &>/dev/null; then
            OS="redhat"
        else
            echo "Unsupported Linux distribution."
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        echo "Unsupported OS: $OSTYPE"
        exit 1
    fi
}

# Install Java 17
install_java() {
    case $OS in
        "ubuntu")
            sudo apt update
            sudo apt install -y openjdk-17-jdk
            ;;
        "redhat")
            sudo yum install -y java-17-openjdk
            ;;
        "macos")
            brew install openjdk@17
            sudo ln -sfn "$(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk-17.jdk
            ;;
        *)
            echo "Unsupported OS for Java installation."
            exit 1
            ;;
    esac
    echo "Java 17 installed successfully."
}

# Install Gradle
install_gradle() {
    case $OS in
        "ubuntu" | "redhat")
            sudo apt update || sudo yum update -y
            sudo apt install -y wget unzip || sudo yum install -y wget unzip
            wget https://services.gradle.org/distributions/gradle-8.4-bin.zip -P /tmp
            sudo unzip -d /opt/gradle /tmp/gradle-8.4-bin.zip
            sudo ln -sfn /opt/gradle/gradle-8.4/bin/gradle /usr/bin/gradle
            ;;
        "macos")
            brew install gradle
            ;;
        *)
            echo "Unsupported OS for Gradle installation."
            exit 1
            ;;
    esac
    echo "Gradle installed successfully."
}

# Main Script Execution
detect_os
check_java
check_gradle

echo "All dependencies are installed and ready!"
