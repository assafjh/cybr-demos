#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
INSTALL_DIR="$SCRIPT_DIR/tomcat"
TOMCAT_PORT=${1:-8081}  # Default port is 8081 if not specified

# Function to start Tomcat
start_tomcat() {
  local install_dir=$1

  echo "Starting Tomcat..."
  $install_dir/bin/startup.sh
  echo "Tomcat started. Access it at http://localhost:$TOMCAT_PORT"
  echo "To stop Tomcat, run $install_dir/bin/shutdown.sh"
}

# Main script
start_tomcat $INSTALL_DIR

