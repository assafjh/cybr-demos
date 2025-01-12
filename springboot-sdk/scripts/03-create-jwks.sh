#!/bin/bash

# Stop the script if any command fails
set -e

# Define directories
OUTPUT_DIR="../compiled"

# Find the JAR file in the compiled directory
JAR_FILE=$(find "$OUTPUT_DIR" -name "jwks-generator*.jar" | head -n 1)

if [ -z "$JAR_FILE" ]; then
    echo "Error: No JAR file found in $OUTPUT_DIR. Please compile the project first using ./compile.sh."
    exit 1
fi

# Run the JAR file
echo "Running JAR file: $JAR_FILE"
java -jar "$JAR_FILE"

# Move the *.pem and *.json files to the output directory
echo "Moving PEM and JSON files to $OUTPUT_DIR"

# Move all .pem files
if ls *.pem 1> /dev/null 2>&1; then
    mv *.pem "$OUTPUT_DIR"
else
    echo "No .pem files found to move."
fi

# Move all .json files
if ls *.json 1> /dev/null 2>&1; then
    mv *.json "$OUTPUT_DIR"
else
    echo "No .json files found to move."
fi

echo "Completed!"
