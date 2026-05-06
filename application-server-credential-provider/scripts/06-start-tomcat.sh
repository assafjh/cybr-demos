#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TOMCAT_HOME="$SCRIPT_DIR/tomcat"

if [ -f "$TOMCAT_HOME/bin/startup.sh" ]; then
    echo "🚀 Starting Tomcat..."
    "$TOMCAT_HOME/bin/startup.sh"
    echo "📊 Monitor logs with: tail -f $TOMCAT_HOME/logs/catalina.out"
else
    echo "❌ Error: Tomcat not found. Run scripts 02 and 05 first."
fi