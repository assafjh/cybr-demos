#!/bin/bash

# Stop the script if any command fails
set -e

# Script path
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TARGET_DIR="$SCRIPT_DIR"/../compiled/

cd "$TARGET_DIR" || { echo "Error: Failed to change directory to $TARGET_DIR"; exit 1; }

# Find the JAR file in the compiled directory
JAR_FILE=demo-app-0.0.1-SNAPSHOT.jar

if [ -z "$JAR_FILE" ]; then
    echo "Error: No JAR file found in $OUTPUT_DIR. Please compile the project first using ./compile.sh."
    exit 1
fi

# List available profiles
AVAILABLE_PROFILES=("dev" "prod")

# Function to display available profiles
show_profiles() {
    echo "Available profiles:"
    for profile in "${AVAILABLE_PROFILES[@]}"; do
        echo "  - $profile"
    done
}

# Function to check if a value is in an array
is_valid_profile() {
    local profile=$1
    for valid_profile in "${AVAILABLE_PROFILES[@]}"; do
        if [ "$valid_profile" == "$profile" ]; then
            return 0
        fi
    done
    return 1
}

# Check if a profile is provided as an argument
if [ -z "$1" ]; then
    echo "No profile specified."
    show_profiles
    echo "Usage: $0 <profile>"
    exit 1
fi

PROFILE=$1

# Validate the provided profile
if ! is_valid_profile "$PROFILE"; then
    echo "Invalid profile: $PROFILE"
    show_profiles
    exit 1
fi

echo "Running the application with profile: $PROFILE"

# Run the application with the chosen profile
java -jar -Dspring.profiles.active="$PROFILE" "$JAR_FILE"
