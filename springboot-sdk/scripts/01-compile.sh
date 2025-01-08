#!/bin/bash

# Stop the script if any command fails
set -e

# Define directories
CODE_DIR="../code"
OUTPUT_DIR="../compiled"

# Move to the code directory
cd "$CODE_DIR"

echo "Cleaning and building the project..."

# Clean and build the project
./gradlew clean build

# Create the compiled directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Find the built JAR file
JAR_FILE=$(find build/libs -name "*.jar" | head -n 1)

if [ -z "$JAR_FILE" ]; then
    echo "Error: No JAR file was found after build."
    exit 1
fi

# Move the JAR file to the compiled directory
mv "$JAR_FILE" "$OUTPUT_DIR"

echo "Build completed successfully!"
echo "JAR file moved to: $OUTPUT_DIR"
