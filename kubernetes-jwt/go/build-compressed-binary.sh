#!/bin/bash
# This script will build and compress messenger go app.
# If needed, the script will install upx and goupx
# It is assumed that GO is installed
# Meant for Linux distros
#============ Variables ===============
# Script path
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) 
#============ Script ===============
# Check for os implementation type
if [ "$(uname | tr "[:upper:]" "[:lower:]")" != "linux" ]; then
    echo "Script meant to run only on linux distros" 
    exit 1
fi
# Check if go installed
cd "$SCRIPT_DIR" || exit 1
if ! command -v go >/dev/null 2>&1 
then
    echo "Please install GO"
    exit 1
fi
# Installing goupx if needed
if ! command -v goupx >/dev/null 2>&1 
then
    echo "Installing goupx"
    GOPATH=${HOME}/.local go install github.com/pwaller/goupx@latest
fi
# Installing upx if needed
if ! command -v upx >/dev/null 2>&1 
then
    echo "Installing upx"
    wget https://github.com/upx/upx/releases/download/v4.0.2/upx-4.0.2-amd64_linux.tar.xz
    tar xf ./upx-4.0.2-amd64_linux.tar.xz
    mv ./upx-4.0.2-amd64_linux/upx "$HOME"/.local/bin/
    rm -rf upx-4.0.2-amd64_linux upx-4.0.2-amd64_linux.tar.xz
fi
# Compiling
cd ./src || exit 1
go build -o ../bin -ldflags="-s"
# Compressing
cd ../bin || exit 1
upx -9 -k ./messenger