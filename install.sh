#!/bin/bash

# Installation script for the firewall

echo "Updating package list... (This may require sudo password)"
# Check for sudo permissions
if ! [ "$(id -u)" = 0 ]; then
  if ! command -v sudo &> /dev/null; then
    echo "sudo command not found. Please run this script as root."
    exit 1
  fi
fi

# Update and install dependencies
sudo apt-get update
sudo apt-get install -y dialog iptables iptables-persistent

# Make the main firewall script executable
echo "Setting execute permissions for firewall.sh..."
chmod +x firewall.sh

echo "Installation complete."
echo "You can now run the firewall by executing: ./firewall.sh"
