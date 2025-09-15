#!/bin/bash

# Quick EasyTier Installation Script for Ubuntu/Debian
# This script provides a simplified installation process

set -e

RED_COLOR='\e[1;31m'
GREEN_COLOR='\e[1;32m'
YELLOW_COLOR='\e[1;33m'
BLUE_COLOR='\e[1;34m'
CYAN_COLOR='\e[1;36m'
RES='\e[0m'

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED_COLOR}This script requires root privileges!${RES}"
    echo "Please run with sudo: sudo ./install_easytier_ubuntu.sh"
    exit 1
fi

# Update system
echo -e "${BLUE_COLOR}Updating system packages...${RES}"
apt-get update -y

# Install required packages
echo -e "${BLUE_COLOR}Installing required packages...${RES}"
apt-get install -y curl unzip wget

# Download and run the main installer
echo -e "${BLUE_COLOR}Downloading EasyTier installer...${RES}"
wget -O easytier_installer.sh https://raw.githubusercontent.com/EasyTier/EasyTier/main/script/install.sh
chmod +x easytier_installer.sh

echo -e "${GREEN_COLOR}Starting EasyTier installation...${RES}"
echo -e "${YELLOW_COLOR}The installer will guide you through the setup process.${RES}\n"

# Run the installer
./easytier_installer.sh

# Cleanup
rm -f easytier_installer.sh

echo -e "\n${GREEN_COLOR}Installation completed!${RES}"
echo -e "${CYAN_COLOR}You can now manage your EasyTier network using:${RES}"
echo -e "  ${GREEN_COLOR}easytier-cli peer${RES} - View connected peers"
echo -e "  ${GREEN_COLOR}easytier-cli route${RES} - View network routes"
echo -e "  ${GREEN_COLOR}systemctl status easytier@default${RES} - Check service status"
