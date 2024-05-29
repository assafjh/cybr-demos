#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Check if Java is installed
if ! command -v java &> /dev/null; then
    echo "Java is not installed. Please install Java to proceed."
    exit 1
fi

# Define the paths
CYBERARK_SDK_JAR="/opt/CARKaim/sdk/javapasswordsdk.jar"
OUTPUT_JAR="$SCRIPT_DIR/../compiled/CyberArkCredentialProvider.jar"
PROPERTIES_FILE="$SCRIPT_DIR/../compiled/config.properties"

# Check if the properties file exists
if [ ! -f $PROPERTIES_FILE ]; then
    echo "Properties file $PROPERTIES_FILE not found. Please create the file and try again."
    exit 1
fi

# Run the JAR file
java -cp .:$CYBERARK_SDK_JAR:$OUTPUT_JAR CyberArkCredentialProvider
