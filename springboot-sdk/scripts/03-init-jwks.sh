#!/bin/bash

# Stop the script if any command fails
set -e

# Define directories
OUTPUT_DIR="../compiled"

# Find the JAR file in the compiled directory
JAR_FILE=$(find "$OUTPUT_DIR" -name "*.jar" | head -n 1)

if [ -z "$JAR_FILE" ]; then
    echo "Error: No JAR file found in $OUTPUT_DIR. Please compile the project first using ./compile.sh."
    exit 1
fi

java -Dmode=init -jar "$JAR_FILE"
