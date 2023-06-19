#!/bin/bash
if ! command -v "pip3" &> /dev/null
then
    echo "Please install pip3 and re-run the script"
    exit 1
fi
pip3 install -r ../python/requirements.txt
