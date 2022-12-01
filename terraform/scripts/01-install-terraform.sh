#!/bin/bash
# This script will install terrafrom on your machine.
#============ Functions ===============
# This function will attempt to locate your machine OS.
function LOCATE_DISTRO() {
    UNAME=$(uname | tr "[:upper:]" "[:lower:]")
    # If Linux, try to determine specific distribution
    if [ "$UNAME" == "linux" ]; then
        # If available, use LSB to identify distribution
        if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
            DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
        # Otherwise, use release info file
        else
            DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
        fi
    fi
    # For everything else (or if above failed), just use generic identifier
    [ "$DISTRO" == "" ] && DISTRO=$UNAME
    unset UNAME
    echo "$DISTRO"
}
#============ Script ===============
DISTRO=$(LOCATE_DISTRO)
# Installation per DISTRO.
case "$DISTRO" in 
    *"redhat"*)
    echo "RHEL"
    sudo yum install -y yum-utils epel-release
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    sudo yum -y install terraform
    ;;
    *"darwin"*)
    echo "MacOS - assuming brew is installed"
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
    ;;
    *"Ubuntu"*)
    echo "Ubuntu"
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
    wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    sudo apt update
    sudo apt-get install terraform
    ;;
    *)
    echo "$DISTRO not supported."
    ;;
esac