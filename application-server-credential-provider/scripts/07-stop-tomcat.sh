#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TOMCAT_HOME="$SCRIPT_DIR/tomcat"

if [ -f "$TOMCAT_HOME/bin/shutdown.sh" ]; then
    echo "🛑 Stopping Tomcat..."
    "$TOMCAT_HOME/bin/shutdown.sh"
else
    echo "⚠️ Tomcat shutdown script not found."
fi