#!/bin/bash

# EasyTier Interactive Installer Script
# Enhanced version with network setup options

RED_COLOR='\e[1;31m'
GREEN_COLOR='\e[1;32m'
YELLOW_COLOR='\e[1;33m'
BLUE_COLOR='\e[1;34m'
PINK_COLOR='\e[1;35m'
CYAN_COLOR='\e[1;36m'
SHAN='\e[1;33;5m'
RES='\e[0m'

# Global variables
INSTALL_PATH='/opt/easytier'
NETWORK_NAME=""
NETWORK_SECRET=""
EXISTING_NODE_IP=""
IS_FIRST_NODE=false
SKIP_FOLDER_VERIFY=false
SKIP_FOLDER_FIX=false
NO_GH_PROXY=false
GH_PROXY='https://ghfast.top/'

# Banner
show_banner() {
    clear
    echo -e "${CYAN_COLOR}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    EasyTier Mesh Network                     ║"
    echo "║                   Interactive Installer                     ║"
    echo "║                                                              ║"
    echo "║  A simple, decentralized mesh VPN with WireGuard support    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RES}\n"
}

# Help function
HELP() {
    echo -e "\r\n${GREEN_COLOR}EasyTier Interactive Installer Help${RES}\r\n"
    echo "Usage: ./easytier_installer.sh [options]"
    echo
    echo "Options:"
    echo "  --skip-folder-verify  Skip folder verification during installation"
    echo "  --skip-folder-fix     Skip automatic folder path fixing"
    echo "  --no-gh-proxy        Disable GitHub proxy"
    echo "  --gh-proxy URL       Set custom GitHub proxy URL"
    echo "  --help               Show this help message"
    echo
    echo "Examples:"
    echo "  ./easytier_installer.sh"
    echo "  ./easytier_installer.sh --no-gh-proxy"
    echo "  ./easytier_installer.sh --gh-proxy https://your-proxy.com/"
    echo
    echo "This installer will guide you through:"
    echo "  1. Network setup (first node or joining existing network)"
    echo "  2. Network name and secret configuration"
    echo "  3. Automatic installation and configuration"
    echo "  4. Service setup and startup"
}

# Parse command line arguments
parse_arguments() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --skip-folder-verify) SKIP_FOLDER_VERIFY=true ;;
            --skip-folder-fix) SKIP_FOLDER_FIX=true ;;
            --no-gh-proxy) NO_GH_PROXY=true ;;
            --gh-proxy) 
                if [ -n "$2" ]; then
                    GH_PROXY=$2
                    shift
                else
                    echo "Error: --gh-proxy requires a URL"
                    exit 1
                fi
                ;;
            --help) HELP; exit 0 ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done
}

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE_COLOR}Checking prerequisites...${RES}"
    
    # Check if running as root
    if [ "$(id -u)" != "0" ]; then
        echo -e "\r\n${RED_COLOR}This script requires root privileges!${RES}\r\n"
        echo "Please run with sudo: sudo ./easytier_installer.sh"
        exit 1
    fi
    
    # Check if unzip is installed
    if ! command -v unzip >/dev/null 2>&1; then
        echo -e "\r\n${RED_COLOR}Error: unzip is not installed${RES}\r\n"
        echo "Installing unzip..."
        apt-get update && apt-get install -y unzip || yum install -y unzip || dnf install -y unzip
    fi
    
    # Check if curl is installed
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "\r\n${RED_COLOR}Error: curl is not installed${RES}\r\n"
        echo "Installing curl..."
        apt-get update && apt-get install -y curl || yum install -y curl || dnf install -y curl
    fi
    
    echo -e "${GREEN_COLOR}✓ Prerequisites check completed${RES}\n"
}

# Detect platform
detect_platform() {
    echo -e "${BLUE_COLOR}Detecting platform...${RES}"
    
    if command -v arch >/dev/null 2>&1; then
        platform=$(arch)
    else
        platform=$(uname -m)
    fi
    
    case "$platform" in
        amd64 | x86_64) ARCH="x86_64" ;;
        arm64 | aarch64 | *armv8*) ARCH="aarch64" ;;
        *armv7*) ARCH="armv7" ;;
        *arm*) ARCH="arm" ;;
        mips) ARCH="mips" ;;
        mipsel) ARCH="mipsel" ;;
        *) ARCH="UNKNOWN" ;;
    esac
    
    # Support hf
    if [[ "$ARCH" == "armv7" || "$ARCH" == "arm" ]]; then
        if cat /proc/cpuinfo | grep Features | grep -i 'half' >/dev/null 2>&1; then
            ARCH=${ARCH}hf
        fi
    fi
    
    echo -e "${GREEN_COLOR}✓ Platform detected: ${ARCH} (${platform})${RES}\n"
    
    if [ "$ARCH" == "UNKNOWN" ]; then
        echo -e "\r\n${RED_COLOR}Unsupported platform: ${platform}${RES}\r\n"
        echo "Please install manually or contact support"
        exit 1
    fi
}

# Detect init system
detect_init_system() {
    echo -e "${BLUE_COLOR}Detecting init system...${RES}"
    
    if command -v systemctl >/dev/null 2>&1; then
        INIT_SYSTEM="systemd"
    elif command -v rc-update >/dev/null 2>&1; then
        INIT_SYSTEM="openrc"
    else
        echo -e "\r\n${RED_COLOR}Error: Unsupported init system (neither systemd nor OpenRC found)${RES}\r\n"
        exit 1
    fi
    
    echo -e "${GREEN_COLOR}✓ Init system detected: ${INIT_SYSTEM}${RES}\n"
}

# Interactive network setup
setup_network() {
    echo -e "${YELLOW_COLOR}╔══════════════════════════════════════════════════════════════╗${RES}"
    echo -e "${YELLOW_COLOR}║                    Network Setup                            ║${RES}"
    echo -e "${YELLOW_COLOR}╚══════════════════════════════════════════════════════════════╝${RES}\n"
    
    echo -e "${CYAN_COLOR}Are you setting up the first node in your mesh network?${RES}"
    echo -e "${BLUE_COLOR}1) Yes - Create new mesh network${RES}"
    echo -e "${BLUE_COLOR}2) No - Join existing mesh network${RES}"
    echo
    
    while true; do
        read -p "Please choose (1 or 2): " choice
        case $choice in
            1)
                IS_FIRST_NODE=true
                echo -e "${GREEN_COLOR}✓ Setting up as first node${RES}\n"
                break
                ;;
            2)
                IS_FIRST_NODE=false
                echo -e "${GREEN_COLOR}✓ Setting up as additional node${RES}\n"
                break
                ;;
            *)
                echo -e "${RED_COLOR}Invalid choice. Please enter 1 or 2.${RES}"
                ;;
        esac
    done
    
    # Get network name
    echo -e "${CYAN_COLOR}Enter your network name:${RES}"
    echo -e "${BLUE_COLOR}(This will be used to identify your mesh network)${RES}"
    while true; do
        read -p "Network name: " NETWORK_NAME
        if [ -n "$NETWORK_NAME" ]; then
            echo -e "${GREEN_COLOR}✓ Network name set to: ${NETWORK_NAME}${RES}\n"
            break
        else
            echo -e "${RED_COLOR}Network name cannot be empty. Please try again.${RES}"
        fi
    done
    
    # Get network secret
    echo -e "${CYAN_COLOR}Enter your network secret:${RES}"
    echo -e "${BLUE_COLOR}(This will be used to secure your mesh network)${RES}"
    while true; do
        read -s -p "Network secret: " NETWORK_SECRET
        echo
        if [ -n "$NETWORK_SECRET" ]; then
            echo -e "${GREEN_COLOR}✓ Network secret configured${RES}\n"
            break
        else
            echo -e "${RED_COLOR}Network secret cannot be empty. Please try again.${RES}"
        fi
    done
    
    # If not first node, get existing node IP
    if [ "$IS_FIRST_NODE" = false ]; then
        echo -e "${CYAN_COLOR}Enter the IP address of an existing node in your network:${RES}"
        echo -e "${BLUE_COLOR}(This can be a public IP or internal IP if on same network)${RES}"
        while true; do
            read -p "Existing node IP: " EXISTING_NODE_IP
            if [[ $EXISTING_NODE_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                echo -e "${GREEN_COLOR}✓ Will connect to node at: ${EXISTING_NODE_IP}${RES}\n"
                break
            else
                echo -e "${RED_COLOR}Invalid IP address format. Please try again.${RES}"
            fi
        done
    fi
    
    # Summary
    echo -e "${YELLOW_COLOR}╔══════════════════════════════════════════════════════════════╗${RES}"
    echo -e "${YELLOW_COLOR}║                    Configuration Summary                    ║${RES}"
    echo -e "${YELLOW_COLOR}╚══════════════════════════════════════════════════════════════╝${RES}"
    echo -e "${GREEN_COLOR}Network Name: ${NETWORK_NAME}${RES}"
    echo -e "${GREEN_COLOR}Network Secret: [HIDDEN]${RES}"
    if [ "$IS_FIRST_NODE" = true ]; then
        echo -e "${GREEN_COLOR}Node Type: First Node (Creating new network)${RES}"
    else
        echo -e "${GREEN_COLOR}Node Type: Additional Node (Joining existing network)${RES}"
        echo -e "${GREEN_COLOR}Connect to: ${EXISTING_NODE_IP}${RES}"
    fi
    echo
    
    read -p "Continue with installation? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW_COLOR}Installation cancelled.${RES}"
        exit 0
    fi
}

# Check installation path
check_install_path() {
    echo -e "${BLUE_COLOR}Checking installation path...${RES}"
    
    if ! $SKIP_FOLDER_VERIFY; then
        if [ -f "$INSTALL_PATH/easytier-core" ]; then
            echo -e "${RED_COLOR}EasyTier is already installed in $INSTALL_PATH${RES}"
            echo "Please choose another path or use 'update' command"
            echo -e "Or use ${GREEN_COLOR}--skip-folder-verify${RES} to skip"
            exit 1
        fi
    fi
    
    if [ ! -d "$INSTALL_PATH/" ]; then
        mkdir -p $INSTALL_PATH
        echo -e "${GREEN_COLOR}✓ Created installation directory: $INSTALL_PATH${RES}"
    else
        if ! $SKIP_FOLDER_VERIFY; then
            if [ -n "$(ls -A $INSTALL_PATH)" ]; then
                echo -e "${RED_COLOR}Installation directory is not empty: $INSTALL_PATH${RES}"
                echo "EasyTier requires an empty directory for installation"
                echo -e "Or use ${GREEN_COLOR}--skip-folder-verify${RES} to skip"
                exit 1
            fi
        fi
    fi
    
    echo -e "${GREEN_COLOR}✓ Installation path verified${RES}\n"
}

# Download and install EasyTier
install_easytier() {
    echo -e "${BLUE_COLOR}Downloading EasyTier...${RES}"
    
    # Get latest version
    RESPONSE=$(curl -s "https://api.github.com/repos/EasyTier/EasyTier/releases/latest")
    LATEST_VERSION=$(echo "$RESPONSE" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    LATEST_VERSION=$(echo -e "$LATEST_VERSION" | tr -d '[:space:]')
    
    if [ -z "$LATEST_VERSION" ]; then
        echo -e "\r\n${RED_COLOR}Failed to get latest version. Check your internet connection.${RES}\r\n"
        exit 1
    fi
    
    echo -e "${GREEN_COLOR}✓ Latest version: ${LATEST_VERSION}${RES}"
    
    # Download
    echo -e "${BLUE_COLOR}Downloading EasyTier ${LATEST_VERSION}...${RES}"
    rm -rf /tmp/easytier_tmp_install.zip
    BASE_URL="https://github.com/EasyTier/EasyTier/releases/latest/download/easytier-linux-${ARCH}-${LATEST_VERSION}.zip"
    DOWNLOAD_URL=$($NO_GH_PROXY && echo "$BASE_URL" || echo "${GH_PROXY}${BASE_URL}")
    
    echo -e "${BLUE_COLOR}Download URL: ${DOWNLOAD_URL}${RES}"
    
    if curl -L ${DOWNLOAD_URL} -o /tmp/easytier_tmp_install.zip --progress-bar; then
        echo -e "${GREEN_COLOR}✓ Download completed${RES}"
    else
        echo -e "${RED_COLOR}Download failed!${RES}"
        exit 1
    fi
    
    # Extract
    echo -e "${BLUE_COLOR}Extracting files...${RES}"
    unzip -o /tmp/easytier_tmp_install.zip -d $INSTALL_PATH/ >/dev/null 2>&1
    mkdir -p $INSTALL_PATH/config
    mv $INSTALL_PATH/easytier-linux-${ARCH}/* $INSTALL_PATH/ 2>/dev/null
    rm -rf $INSTALL_PATH/easytier-linux-${ARCH}/
    chmod +x $INSTALL_PATH/easytier-core $INSTALL_PATH/easytier-cli
    
    if [ -f $INSTALL_PATH/easytier-core ] && [ -f $INSTALL_PATH/easytier-cli ]; then
        echo -e "${GREEN_COLOR}✓ Installation completed${RES}\n"
    else
        echo -e "${RED_COLOR}Installation failed!${RES}"
        exit 1
    fi
}

# Create configuration
create_config() {
    echo -e "${BLUE_COLOR}Creating configuration...${RES}"
    
    # Generate instance name
    INSTANCE_NAME="node-$(hostname)-$(date +%s | tail -c 6)"
    
    # Create config file
    cat >$INSTALL_PATH/config/default.conf <<EOF
instance_name = "${INSTANCE_NAME}"
dhcp = true
listeners = [
    "tcp://0.0.0.0:11010",
    "udp://0.0.0.0:11010",
    "wg://0.0.0.0:11011",
    "ws://0.0.0.0:11011/",
    "wss://0.0.0.0:11012/",
]
exit_nodes = []
rpc_portal = "0.0.0.0:8080"

EOF

    # Add peer configuration if not first node
    if [ "$IS_FIRST_NODE" = false ]; then
        cat >>$INSTALL_PATH/config/default.conf <<EOF
[[peer]]
uri = "tcp://${EXISTING_NODE_IP}:11010"

EOF
    else
        # Add public node for first node
        cat >>$INSTALL_PATH/config/default.conf <<EOF
[[peer]]
uri = "tcp://public.easytier.cn:11010"

EOF
    fi
    
    # Add network identity
    cat >>$INSTALL_PATH/config/default.conf <<EOF
[network_identity]
network_name = "${NETWORK_NAME}"
network_secret = "${NETWORK_SECRET}"

[flags]
default_protocol = "udp"
dev_name = ""
enable_encryption = true
enable_ipv6 = true
mtu = 1380
latency_first = false
enable_exit_node = false
no_tun = false
use_smoltcp = false
foreign_network_whitelist = "*"
disable_p2p = false
relay_all_peer_rpc = false
disable_udp_hole_punching = false
EOF

    echo -e "${GREEN_COLOR}✓ Configuration created${RES}\n"
}

# Setup service
setup_service() {
    echo -e "${BLUE_COLOR}Setting up service...${RES}"
    
    if [ "$INIT_SYSTEM" = "systemd" ]; then
        # Create systemd service
        cat >/etc/systemd/system/easytier@.service <<EOF
[Unit]
Description=EasyTier Mesh Network Service
Wants=network.target
After=network.target network.service
StartLimitIntervalSec=0

[Service]
Type=simple
WorkingDirectory=$INSTALL_PATH
ExecStart=$INSTALL_PATH/easytier-core -c $INSTALL_PATH/config/%i.conf
Restart=always
RestartSec=1s
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF
        
        # Enable and start service
        systemctl daemon-reload
        systemctl enable easytier@default >/dev/null 2>&1
        systemctl start easytier@default
        
    elif [ "$INIT_SYSTEM" = "openrc" ]; then
        # Create OpenRC service
        cat >/etc/init.d/easytier <<EOF
#!/sbin/openrc-run

name="EasyTier"
description="EasyTier Mesh Network Service"
command="$INSTALL_PATH/easytier-core"
command_args="-c $INSTALL_PATH/config/default.conf"
command_user="nobody:nobody"
command_background=true

pidfile="/run/\${RC_SVCNAME}.pid"

depend() {
    need net
}
EOF
        chmod +x /etc/init.d/easytier
        rc-update add easytier default
        rc-service easytier start
    fi
    
    # Create symlinks
    ln -sf $INSTALL_PATH/easytier-core /usr/sbin/easytier-core
    ln -sf $INSTALL_PATH/easytier-cli /usr/sbin/easytier-cli
    
    echo -e "${GREEN_COLOR}✓ Service setup completed${RES}\n"
}

# Wait for service to start
wait_for_service() {
    echo -e "${BLUE_COLOR}Waiting for service to start...${RES}"
    
    for i in {1..30}; do
        if [ "$INIT_SYSTEM" = "systemd" ]; then
            if systemctl is-active --quiet easytier@default; then
                echo -e "${GREEN_COLOR}✓ Service is running${RES}\n"
                return 0
            fi
        else
            if rc-service easytier status >/dev/null 2>&1; then
                echo -e "${GREEN_COLOR}✓ Service is running${RES}\n"
                return 0
            fi
        fi
        
        echo -n "."
        sleep 1
    done
    
    echo -e "\n${YELLOW_COLOR}Service may still be starting. Please check manually.${RES}\n"
}

# Show success message
show_success() {
    clear
    echo -e "${GREEN_COLOR}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Installation Complete!                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RES}\n"
    
    echo -e "${GREEN_COLOR}✓ EasyTier has been successfully installed and configured!${RES}\n"
    
    echo -e "${CYAN_COLOR}Network Information:${RES}"
    echo -e "  Network Name: ${GREEN_COLOR}${NETWORK_NAME}${RES}"
    echo -e "  Instance Name: ${GREEN_COLOR}${INSTANCE_NAME}${RES}"
    if [ "$IS_FIRST_NODE" = true ]; then
        echo -e "  Node Type: ${GREEN_COLOR}First Node (Network Creator)${RES}"
    else
        echo -e "  Node Type: ${GREEN_COLOR}Additional Node${RES}"
        echo -e "  Connected to: ${GREEN_COLOR}${EXISTING_NODE_IP}${RES}"
    fi
    
    echo -e "\n${CYAN_COLOR}Service Management:${RES}"
    if [ "$INIT_SYSTEM" = "systemd" ]; then
        echo -e "  Status: ${GREEN_COLOR}systemctl status easytier@default${RES}"
        echo -e "  Start:  ${GREEN_COLOR}systemctl start easytier@default${RES}"
        echo -e "  Stop:   ${GREEN_COLOR}systemctl stop easytier@default${RES}"
        echo -e "  Restart: ${GREEN_COLOR}systemctl restart easytier@default${RES}"
    else
        echo -e "  Status: ${GREEN_COLOR}rc-service easytier status${RES}"
        echo -e "  Start:  ${GREEN_COLOR}rc-service easytier start${RES}"
        echo -e "  Stop:   ${GREEN_COLOR}rc-service easytier stop${RES}"
        echo -e "  Restart: ${GREEN_COLOR}rc-service easytier restart${RES}"
    fi
    
    echo -e "\n${CYAN_COLOR}Network Management:${RES}"
    echo -e "  View peers:     ${GREEN_COLOR}easytier-cli peer${RES}"
    echo -e "  View routes:    ${GREEN_COLOR}easytier-cli route${RES}"
    echo -e "  View node info: ${GREEN_COLOR}easytier-cli node${RES}"
    
    echo -e "\n${CYAN_COLOR}Web Interface:${RES}"
    echo -e "  URL: ${GREEN_COLOR}http://$(hostname -I | awk '{print $1}'):8080${RES}"
    echo -e "  (Make sure port 8080 is open in firewall)"
    
    echo -e "\n${CYAN_COLOR}Firewall Ports:${RES}"
    echo -e "  ${GREEN_COLOR}11010/udp${RES} - Main mesh communication"
    echo -e "  ${GREEN_COLOR}11010/tcp${RES} - Main mesh communication"
    echo -e "  ${GREEN_COLOR}11011/tcp${RES} - WireGuard"
    echo -e "  ${GREEN_COLOR}11012/tcp${RES} - WebSocket SSL"
    echo -e "  ${GREEN_COLOR}8080/tcp${RES}  - Web interface"
    
    echo -e "\n${YELLOW_COLOR}Next Steps:${RES}"
    if [ "$IS_FIRST_NODE" = true ]; then
        echo -e "  1. Share your network name and secret with other nodes"
        echo -e "  2. Provide your public IP to other nodes for connection"
        echo -e "  3. Configure firewall to allow incoming connections"
    else
        echo -e "  1. Verify connection with: ${GREEN_COLOR}easytier-cli peer${RES}"
        echo -e "  2. Test connectivity with other nodes in the network"
    fi
    
    echo -e "\n${GREEN_COLOR}Installation completed successfully! 🎉${RES}\n"
}

# Cleanup function
cleanup() {
    rm -rf /tmp/easytier_tmp_*
}

# Main function
main() {
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Show banner
    show_banner
    
    # Parse arguments
    parse_arguments "$@"
    
    # Check prerequisites
    check_prerequisites
    
    # Detect platform and init system
    detect_platform
    detect_init_system
    
    # Interactive network setup
    setup_network
    
    # Check installation path
    check_install_path
    
    # Install EasyTier
    install_easytier
    
    # Create configuration
    create_config
    
    # Setup service
    setup_service
    
    # Wait for service
    wait_for_service
    
    # Show success message
    show_success
}

# Run main function
main "$@"
