#!/bin/bash

# Stop the script if any command fails
set -e

# Define directories
CODE_DIR="../code"
OUTPUT_DIR="../compiled"

# Move to the code directory
echo "Changing directory to $CODE_DIR..."
cd "$CODE_DIR" || { echo "Error: Failed to change directory to $CODE_DIR"; exit 1; }

echo "Cleaning and building the Maven project..."

# Clean and build the project with Maven
mvn clean package -DskipTests

# Create the compiled directory if it doesn't exist
echo "Ensuring the output directory exists..."
mkdir -p "$OUTPUT_DIR"

# Find the built JAR files in both target directories
JAR_FILES=$(find . -type f -name '*.jar')

if [ -z "$JAR_FILES" ]; then
    echo "Error: No JAR files were found after build."
    exit 1
fi

# Move all JAR files to the compiled directory
echo "Moving JAR files to $OUTPUT_DIR..."
for JAR_FILE in $JAR_FILES; do
    mv "$JAR_FILE" "$OUTPUT_DIR"
    echo "Moved: $(basename "$JAR_FILE")"
done

echo "Build completed successfully!"
echo "JAR files moved to: $OUTPUT_DIR/"
