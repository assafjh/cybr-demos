#!/bin/bash
# This script will install Ansible

#========== Script  ===============
# Loading functions snippet
source ./functions
check_if_command_exists python3 
check_if_command_exists pip3
# Installing Ansible
python3 -m pip install --user ansible
export PATH="$PATH:$HOME/.local/bin"
echo "=========================="
ansible --version
echo "=========================="
echo "If not already done, please add ansible to path, you can paste the below at your rc file:"
echo 'export PATH="$PATH:$HOME/.local/bin"'
