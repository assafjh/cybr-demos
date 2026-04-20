#!/bin/bash
# Run this manually after SSH into the Connector EC2
# (user_data auto-install was unreliable in step 1 — doing this manually)

set -e

echo "=== Updating system ==="
sudo dnf update -y

echo "=== Installing Docker ==="
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

echo "=== Docker installed. Version: ==="
sudo docker --version

echo ""
echo "=== Next steps (manual) ==="
echo "1. Log out and back in for docker group to take effect"
echo "2. Go to SIA Console -> Settings -> Connectors"
echo "3. Click 'Install a connector' -> Linux"
echo "4. Copy the install command (contains a temporary token)"
echo "5. Run it on this machine"
echo ""
echo "The SIA install command will be something like:"
echo "  docker run -d --name cyberark-connector ... cyberark/connector:latest"
