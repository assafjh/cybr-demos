#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
INSTALL_DIR="$SCRIPT_DIR/tomcat"

# Function to stop Tomcat
stop_tomcat() {
  local install_dir=$1

  echo "Stopping Tomcat..."
  $install_dir/bin/shutdown.sh
  echo "Tomcat stopped."
}

# Main script
stop_tomcat $INSTALL_DIR

