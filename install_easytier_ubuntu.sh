#!/bin/bash

# EasyTier Installation Script for Ubuntu Server
# Based on the official EasyTier releases from GitHub
# Repository: https://github.com/EasyTier/EasyTier

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/easytier"
SERVICE_NAME="easytier"
CONFIG_DIR="$INSTALL_DIR/config"
BINARY_DIR="$INSTALL_DIR/bin"

# Default configuration
DEFAULT_NETWORK_NAME="my-network"
DEFAULT_NETWORK_SECRET="my-secret-key"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  EasyTier Installation Script  ${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to detect system architecture
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        armv7l)
            echo "armv7"
            ;;
        *)
            print_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
}

# Function to get latest release version
get_latest_version() {
    print_status "Fetching latest EasyTier version..."
    local version=$(curl -s https://api.github.com/repos/EasyTier/EasyTier/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ -z "$version" ]]; then
        print_error "Failed to fetch latest version"
        exit 1
    fi
    echo "$version"
}

# Function to download and extract EasyTier
download_easytier() {
    local version=$1
    local arch=$2
    
    print_status "Downloading EasyTier $version for $arch..."
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Download URL
    local download_url="https://github.com/EasyTier/EasyTier/releases/download/${version}/easytier-linux-${arch}-${version}.zip"
    
    print_status "Download URL: $download_url"
    
    # Download the release
    if ! wget -q --show-progress "$download_url" -O "easytier-${version}.zip"; then
        print_error "Failed to download EasyTier"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Extract the archive
    print_status "Extracting EasyTier..."
    if ! unzip -q "easytier-${version}.zip"; then
        print_error "Failed to extract EasyTier"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BINARY_DIR"
    mkdir -p "$CONFIG_DIR"
    
    # Copy binaries
    local extracted_dir="easytier-linux-${arch}-${version}"
    if [[ -d "$extracted_dir" ]]; then
        cp "$extracted_dir"/* "$BINARY_DIR/"
        chmod +x "$BINARY_DIR"/*
    else
        print_error "Extracted directory not found"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    print_status "EasyTier binaries installed to $BINARY_DIR"
}

# Function to create systemd service
create_systemd_service() {
    print_status "Creating systemd service..."
    
    cat > "/etc/systemd/system/${SERVICE_NAME}@.service" << EOF
[Unit]
Description=EasyTier VPN Service (%i)
Documentation=https://github.com/EasyTier/EasyTier
After=network.target network-online.target
Wants=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$BINARY_DIR/easytier-core -c $CONFIG_DIR/%i.conf
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=easytier

# Security settings
NoNewPrivileges=false
PrivateTmp=false
ProtectSystem=false
ProtectHome=false

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd
    systemctl daemon-reload
    print_status "Systemd service created"
}

# Function to create default configuration
create_default_config() {
    local network_name=${1:-$DEFAULT_NETWORK_NAME}
    local network_secret=${2:-$DEFAULT_NETWORK_SECRET}
    
    print_status "Creating default configuration..."
    
    cat > "$CONFIG_DIR/default.conf" << EOF
# EasyTier Configuration File
# Generated on $(date)

# Instance configuration
instance_name = "default"
dhcp = true

# Network identity
[network_identity]
network_name = "$network_name"
network_secret = "$network_secret"

# Listeners - EasyTier will listen on these addresses
listeners = [
    "tcp://0.0.0.0:11010",
    "udp://0.0.0.0:11010",
    "wg://0.0.0.0:11011",
    "ws://0.0.0.0:11011/",
    "wss://0.0.0.0:11012/",
]

# Peers - Connect to these nodes (optional)
[[peer]]
uri = "tcp://public.easytier.cn:11010"

# RPC portal for CLI access
rpc_portal = "127.0.0.1:15888"

# Exit nodes (empty by default)
exit_nodes = []

# Feature flags
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

    print_status "Default configuration created at $CONFIG_DIR/default.conf"
}

# Function to create CLI wrapper script
create_cli_wrapper() {
    print_status "Creating CLI wrapper script..."
    
    cat > "/usr/local/bin/easytier-cli" << EOF
#!/bin/bash
# EasyTier CLI Wrapper
exec $BINARY_DIR/easytier-cli "\$@"
EOF

    chmod +x "/usr/local/bin/easytier-cli"
    print_status "CLI wrapper created at /usr/local/bin/easytier-cli"
}

# Function to configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    # Check if ufw is available
    if command -v ufw >/dev/null 2>&1; then
        # Allow EasyTier ports
        ufw allow 11010/tcp comment "EasyTier TCP"
        ufw allow 11010/udp comment "EasyTier UDP"
        ufw allow 11011/tcp comment "EasyTier WebSocket"
        ufw allow 11012/tcp comment "EasyTier WebSocket SSL"
        ufw allow 11013/udp comment "EasyTier WireGuard"
        
        print_status "Firewall rules added for EasyTier ports"
    else
        print_warning "UFW not found. Please manually configure firewall to allow ports: 11010-11013"
    fi
}

# Function to start and enable service
start_service() {
    print_status "Starting EasyTier service..."
    
    # Enable and start the service
    systemctl enable "${SERVICE_NAME}@default"
    systemctl start "${SERVICE_NAME}@default"
    
    # Wait a moment for service to start
    sleep 3
    
    # Check service status
    if systemctl is-active --quiet "${SERVICE_NAME}@default"; then
        print_status "EasyTier service started successfully"
    else
        print_error "Failed to start EasyTier service"
        systemctl status "${SERVICE_NAME}@default" --no-pager
        exit 1
    fi
}

# Function to show installation summary
show_summary() {
    echo
    print_header
    print_status "EasyTier installation completed successfully!"
    echo
    echo -e "${GREEN}Installation Details:${NC}"
    echo "  • Installation Directory: $INSTALL_DIR"
    echo "  • Configuration Directory: $CONFIG_DIR"
    echo "  • Service Name: ${SERVICE_NAME}@default"
    echo "  • CLI Command: easytier-cli"
    echo
    echo -e "${GREEN}Service Management:${NC}"
    echo "  • Status:  systemctl status ${SERVICE_NAME}@default"
    echo "  • Start:   systemctl start ${SERVICE_NAME}@default"
    echo "  • Stop:    systemctl stop ${SERVICE_NAME}@default"
    echo "  • Restart: systemctl restart ${SERVICE_NAME}@default"
    echo "  • Logs:    journalctl -u ${SERVICE_NAME}@default -f"
    echo
    echo -e "${GREEN}Configuration:${NC}"
    echo "  • Config File: $CONFIG_DIR/default.conf"
    echo "  • Edit config: nano $CONFIG_DIR/default.conf"
    echo "  • After editing: systemctl restart ${SERVICE_NAME}@default"
    echo
    echo -e "${GREEN}CLI Usage:${NC}"
    echo "  • View peers: easytier-cli peer"
    echo "  • View routes: easytier-cli route"
    echo "  • View node info: easytier-cli node"
    echo
    echo -e "${YELLOW}Important Notes:${NC}"
    echo "  • Default network name: $DEFAULT_NETWORK_NAME"
    echo "  • Change network name and secret in config file"
    echo "  • Firewall ports 11010-11013 should be open"
    echo "  • For public nodes, ensure public IP is accessible"
    echo
    print_status "Installation complete! EasyTier is now running."
}

# Function to show help
show_help() {
    echo "EasyTier Installation Script for Ubuntu"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -n, --network-name NAME    Set network name (default: $DEFAULT_NETWORK_NAME)"
    echo "  -s, --network-secret SECRET Set network secret (default: $DEFAULT_NETWORK_SECRET)"
    echo "  -d, --install-dir DIR      Set installation directory (default: $INSTALL_DIR)"
    echo "  -v, --version VERSION      Install specific version (default: latest)"
    echo "  -h, --help                 Show this help message"
    echo
    echo "Examples:"
    echo "  $0                                    # Install with defaults"
    echo "  $0 -n mynetwork -s mysecret          # Install with custom network"
    echo "  $0 -v v2.4.3                        # Install specific version"
    echo "  $0 -d /usr/local/easytier           # Install to custom directory"
}

# Main installation function
main() {
    local network_name="$DEFAULT_NETWORK_NAME"
    local network_secret="$DEFAULT_NETWORK_SECRET"
    local version=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--network-name)
                network_name="$2"
                shift 2
                ;;
            -s|--network-secret)
                network_secret="$2"
                shift 2
                ;;
            -d|--install-dir)
                INSTALL_DIR="$2"
                CONFIG_DIR="$INSTALL_DIR/config"
                BINARY_DIR="$INSTALL_DIR/bin"
                shift 2
                ;;
            -v|--version)
                version="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_header
    
    # Check prerequisites
    check_root
    
    # Check required tools
    for tool in wget unzip curl systemctl; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            print_error "Required tool '$tool' not found. Please install it first."
            exit 1
        fi
    done
    
    # Detect architecture
    local arch=$(detect_arch)
    print_status "Detected architecture: $arch"
    
    # Get version
    if [[ -z "$version" ]]; then
        version=$(get_latest_version)
    fi
    print_status "Installing EasyTier version: $version"
    
    # Install EasyTier
    download_easytier "$version" "$arch"
    create_systemd_service
    create_default_config "$network_name" "$network_secret"
    create_cli_wrapper
    configure_firewall
    start_service
    show_summary
}

# Run main function with all arguments
main "$@"
