#!/bin/bash
# The script will add Conjur TeamCity plugin to the server instance
# It is assumed that the server plugin folder is mounted at $TEAMCITY_DATA_FOLDER/datadir/plugins

#================ Internal =======================
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) 
TEAMCITY_DATA_FOLDER="$SCRIPT_DIR"/teamcity/server

#================ Variables =======================
# TeamCity Conjur Plugin Download URL
CONJUR_PLUGIN_URL=https://github.com/cyberark/conjur-teamcity-plugin/releases/download/v0.0.1/teamcity.zip

#================ Script =======================

curl -s -o "$TEAMCITY_DATA_FOLDER"/datadir/plugins/teamcity.zip -L "${CONJUR_PLUGIN_URL}"

echo -e "Go to TeamCity UI -> Administration -> plugins and enable "Cyberark Conjur Support"