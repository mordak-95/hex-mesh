#!/usr/bin/env bash

set -euo pipefail

# Hex Mesh v2.4.3 Installer
# Advanced VPN Mesh Network Solution

clear_screen() {
  if command -v tput >/dev/null 2>&1; then
    tput reset || printf '\033c'
  elif command -v clear >/dev/null 2>&1; then
    clear
  else
    printf '\033[2J\033[H'
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || return 1
}

ensure_dir() {
  local d="$1"
  if [ ! -d "$d" ]; then
    mkdir -p "$d"
  fi
}

print_header() {
  echo ""
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

abort() {
  echo "Error: $1" >&2
  exit 1
}

press_key() {
  read -p "Press Enter to continue..."
}


print_banner() {
  local MAGENTA CYAN GRAY SEP BOLD RESET
  if [ -t 1 ]; then
    MAGENTA='\033[38;5;141m'  # muted orchid
    CYAN='\033[38;5;81m'     # soft teal
    GRAY='\033[38;5;245m'    # neutral gray text
    SEP='\033[38;5;244m'     # subtle separator
    BOLD='\033[1m'
    RESET='\033[0m'
  else
    MAGENTA=''; CYAN=''; GRAY=''; SEP=''; BOLD=''; RESET=''
  fi

  clear_screen
  echo ""
  echo -e "${SEP}╔════════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${SEP}║                                                                    ║${RESET}"
  echo -e "${SEP}║   ${MAGENTA}${BOLD}██╗  ██╗███████╗██╗  ██╗  ${CYAN} ███╗   ███╗███████╗███████╗██╗  ██╗   ${SEP}║${RESET}"
  echo -e "${SEP}║   ${MAGENTA}${BOLD}██║  ██║██╔════╝╚██╗██╔╝  ${CYAN} ████╗ ████║██╔════╝██╔════╝██║  ██║   ${SEP}║${RESET}"
  echo -e "${SEP}║   ${MAGENTA}${BOLD}███████║█████╗   ╚███╔╝   ${CYAN} ██╔████╔██║█████╗  ███████╗███████║   ${SEP}║${RESET}"
  echo -e "${SEP}║   ${MAGENTA}${BOLD}██╔══██║██╔══╝   ██╔██╗   ${CYAN} ██║╚██╔╝██║██╔══╝  ╚════██║██╔══██║   ${SEP}║${RESET}"
  echo -e "${SEP}║   ${MAGENTA}${BOLD}██║  ██║███████╗██╔╝ ██╗  ${CYAN} ██║ ╚═╝ ██║███████╗███████║██║  ██║   ${SEP}║${RESET}"
  echo -e "${SEP}║   ${MAGENTA}${BOLD}╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝  ${CYAN} ╚═╝     ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝   ${SEP}║${RESET}"
  echo -e "${SEP}║                                                                    ║${RESET}"
  echo -e "${SEP}╚════════════════════════════════════════════════════════════════════╝${RESET}"
  echo -e "${GRAY} Version: 2.4.3 | GitHub: github.com/mordak-95/hex-mesh${RESET}"
  echo -e "${GRAY} Advanced VPN Mesh Network Solution${RESET}\n"
}

install_easytier() {
    local DEST_DIR="/root/easytier"
    local FILES=("easytier-core" "easytier-cli")
    
    # Version 2.4.3 URLs
    local URL_X86="https://github.com/mordak-95/hex-mesh/raw/main/core/v2.4.3/easytier-linux-x86_64/"
    local URL_ARM_SOFT="https://github.com/mordak-95/hex-mesh/raw/main/core/v2.4.3/easytier-linux-armv7/"              
    local URL_ARM_HARD="https://github.com/mordak-95/hex-mesh/raw/main/core/v2.4.3/easytier-linux-armv7hf/"
    
    # Check if already installed
    if [ -d "$DEST_DIR" ]; then    
        local all_files_exist=true
        for file in "${FILES[@]}"; do
            if [ ! -f "$DEST_DIR/$file" ]; then
                all_files_exist=false
                break
            fi
        done
        
        if [ "$all_files_exist" = true ]; then
            echo "✓ Hex Mesh Core v2.4.3 already installed"
            return 0
        fi
    fi
    
    # Detect system architecture
    local ARCH
    ARCH=$(uname -m)
    local URL
    
    case "$ARCH" in
        "x86_64")
            URL=$URL_X86
            ;;
        "armv7l"|"aarch64")
            if [ "$(ldd /bin/ls | grep -c 'armhf')" -eq 1 ]; then
                URL=$URL_ARM_HARD
            else
                URL=$URL_ARM_SOFT
            fi
            ;;
        *)
            abort "Unsupported architecture: $ARCH"
            ;;
    esac

    print_header "Installing Hex Mesh Core v2.4.3"
    ensure_dir "$DEST_DIR"
    
    echo "Downloading binaries for architecture: $ARCH"
    for file in "${FILES[@]}"; do
        echo "  Downloading $file..."
        if ! curl -fsSL "$URL/$file" -o "$DEST_DIR/$file"; then
            abort "Failed to download $file"
        fi
        chmod +x "$DEST_DIR/$file"
    done
    
    echo "✓ Hex Mesh Core v2.4.3 installed successfully"
}



generate_random_secret() {
    openssl rand -hex 6
}

# Install Hex Mesh Core on startup
install_easytier

#Var
EASY_CLIENT='/root/easytier/easytier-cli'
SERVICE_FILE="/etc/systemd/system/hexmesh.service"
    
connect_network_pool() {
    clear_screen
    print_banner
    print_header "Connect to the Mesh Network"
    
    
    # Ask user if they want to create new mesh or join existing
    echo "Select mesh network type:"
    echo "1) Create new mesh network"
    echo "2) Join existing mesh network"
    echo ""
    read -rp "Enter your choice (1 or 2): " MESH_TYPE
    
    case "$MESH_TYPE" in
        1)
            echo "Creating new mesh network..."
            PEER_ADDRESSES=""
            ;;
        2)
            echo "Joining existing mesh network..."
            read -rp "Enter Peer IPv4/IPv6 Address (IP of one of the mesh nodes): " PEER_ADDRESSES
            [[ -z "$PEER_ADDRESSES" ]] && abort "Peer address cannot be empty"
            ;;
        *)
            abort "Invalid choice. Please select 1 or 2"
            ;;
    esac
    
    echo ""
    read -rp "Enter Local IPv4 Address (e.g., 172.17.17.101): " IP_ADDRESS
    [[ -z "$IP_ADDRESS" ]] && abort "Local IP address cannot be empty"
    
    read -rp "Enter Hostname (e.g., IrNode): " HOSTNAME
    [[ -z "$HOSTNAME" ]] && abort "Hostname cannot be empty"
    
    read -rp "Enter Tunnel Port (Default 3033): " PORT
    PORT=${PORT:-3033}
    
    echo ""
    NETWORK_SECRET=$(generate_random_secret)
    echo "✓ Generated Network Secret: $NETWORK_SECRET"
    
    while true; do
        read -rp "Enter Network Secret (recommend using a strong password): " NETWORK_SECRET
        if [[ -n "$NETWORK_SECRET" ]]; then
            break
        else
            echo "Network secret cannot be empty. Please enter a valid secret."
        fi
    done
    
    echo ""
    echo "Select Default Protocol:"
    echo "1) tcp"
    echo "2) udp"
    echo "3) ws"
    echo "4) wss"
    read -rp "Select your desired protocol (e.g., 1 for tcp): " PROTOCOL_CHOICE
    
    case "$PROTOCOL_CHOICE" in
        1) DEFAULT_PROTOCOL="tcp" ;;
        2) DEFAULT_PROTOCOL="udp" ;;
        3) DEFAULT_PROTOCOL="ws" ;;
        4) DEFAULT_PROTOCOL="wss" ;;
        *) echo "Invalid choice. Defaulting to tcp."; DEFAULT_PROTOCOL="tcp" ;;
    esac
    
    echo ""
    read -rp "Enable encryption? (yes/no) [default: no]: " ENCRYPTION_CHOICE
    ENCRYPTION_CHOICE=${ENCRYPTION_CHOICE:-no}
    case "$ENCRYPTION_CHOICE" in
        [Yy]*) 
            ENCRYPTION_OPTION=""
            echo "Encryption is enabled"
            ;;
        *) 
            ENCRYPTION_OPTION="--disable-encryption"
            echo "Encryption is disabled"
            ;;
    esac
    
    # Set multi-thread to disabled by default (no user prompt)
    MULTI_THREAD=""
    
    # Set IPv6 to disabled by default (no user prompt)
    IPV6_MODE="--disable-ipv6"
    
    echo ""
    
    # Process peer addresses
    local PROCESSED_ADDRESSES=()
    if [[ -n "$PEER_ADDRESSES" ]]; then
        IFS=',' read -ra ADDR_ARRAY <<< "$PEER_ADDRESSES"
        for ADDRESS in "${ADDR_ARRAY[@]}"; do
            ADDRESS=$(echo "$ADDRESS" | xargs)
            
            if [[ "$ADDRESS" == *:* ]]; then
                if [[ "$ADDRESS" != \[*\] ]]; then
                    ADDRESS="[$ADDRESS]"
                fi
            fi
        
            if [[ -n "$ADDRESS" ]]; then
                PROCESSED_ADDRESSES+=("${DEFAULT_PROTOCOL}://${ADDRESS}:${PORT}")
            fi
        done
    fi
    
    local JOINED_ADDRESSES
    JOINED_ADDRESSES=$(IFS=' '; echo "${PROCESSED_ADDRESSES[*]}")
    
    local PEER_ADDRESS=""
    if [[ -n "$JOINED_ADDRESSES" ]]; then
        PEER_ADDRESS="--peers ${JOINED_ADDRESSES}"
    fi
    
    local LISTENERS="--listeners ${DEFAULT_PROTOCOL}://[::]:${PORT} ${DEFAULT_PROTOCOL}://0.0.0.0:${PORT}"
    
    print_header "Creating Hex Mesh Service"
    
    # Create systemd service file
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Hex Mesh Network Service v2.4.3
After=network.target

[Service]
ExecStart=/root/easytier/easytier-core -i $IP_ADDRESS $PEER_ADDRESS --hostname $HOSTNAME --network-secret $NETWORK_SECRET --default-protocol $DEFAULT_PROTOCOL $LISTENERS $MULTI_THREAD $ENCRYPTION_OPTION $IPV6_MODE
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd, enable and start the service
    systemctl daemon-reload >/dev/null 2>&1
    systemctl enable hexmesh.service >/dev/null 2>&1
    systemctl start hexmesh.service >/dev/null 2>&1

    echo "✓ Hex Mesh Network Service v2.4.3 started successfully"
    press_key
}


display_peers() {
    clear_screen
    print_banner
    print_header "Network Peers"
    echo "Press Ctrl+C to return to main menu"
    echo ""
    watch -n1 "$EASY_CLIENT" peer
}


restart_hexmesh_service() {
    clear_screen
    print_banner
    print_header "Restart Hex Mesh Service"
    
    if [[ ! -f "$SERVICE_FILE" ]]; then
        echo "✗ Hex Mesh service does not exist"
        press_key
        return 1
    fi
    
    echo "Restarting Hex Mesh service..."
    if systemctl restart hexmesh.service >/dev/null 2>&1; then
        echo "✓ Hex Mesh service restarted successfully"
    else
        echo "✗ Failed to restart Hex Mesh service"
    fi
    
    press_key
}

remove_hexmesh_service() {
    clear_screen
    print_banner
    print_header "Remove Hex Mesh Service"
    
    if [[ ! -f "$SERVICE_FILE" ]]; then
        echo "✗ Hex Mesh service does not exist"
        press_key
        return 1
    fi
    
    echo "Stopping Hex Mesh service..."
    if systemctl stop hexmesh.service >/dev/null 2>&1; then
        echo "✓ Hex Mesh service stopped successfully"
    else
        echo "✗ Failed to stop Hex Mesh service"
        press_key
        return 1
    fi

    echo "Disabling Hex Mesh service..."
    if systemctl disable hexmesh.service >/dev/null 2>&1; then
        echo "✓ Hex Mesh service disabled successfully"
    else
        echo "✗ Failed to disable Hex Mesh service"
        press_key
        return 1
    fi

    echo "Removing Hex Mesh service..."
    if rm -f "$SERVICE_FILE" >/dev/null 2>&1; then
        echo "✓ Hex Mesh service removed successfully"
    else
        echo "✗ Failed to remove Hex Mesh service"
        press_key
        return 1
    fi

    echo "Reloading systemd daemon..."
    if systemctl daemon-reload >/dev/null 2>&1; then
        echo "✓ Systemd daemon reloaded successfully"
    else
        echo "✗ Failed to reload systemd daemon"
        press_key
        return 1
    fi
    
    press_key
}

show_network_secret() {
    clear_screen
    print_banner
    print_header "Network Secret"
    
    if [[ -f "$SERVICE_FILE" ]]; then
        local NETWORK_SECRET
        NETWORK_SECRET=$(grep -oP '(?<=--network-secret )[^ ]+' "$SERVICE_FILE" 2>/dev/null || echo "")
        
        if [[ -n "$NETWORK_SECRET" ]]; then
            echo "Network Secret Key: $NETWORK_SECRET"
        else
            echo "✗ Network Secret key not found"
        fi
    else
        echo "✗ Hex Mesh service does not exist"
    fi
    
    press_key
}

view_service_status() {
    clear_screen
    print_banner
    print_header "Service Status"
    
    if [[ ! -f "$SERVICE_FILE" ]]; then
        echo "✗ Hex Mesh service does not exist"
        press_key
        return 1
    fi
    
    systemctl status hexmesh.service
    press_key
}



# Function to add cron-tab job
add_cron_job() {
    clear_screen
    print_banner
    print_header "Add Cron Job"
    
    local service_name="hexmesh.service"
    
    # Prompt user to choose a restart time interval
    echo "Select the restart time interval:"
    echo ""
    echo "1. Every 30th minute"
    echo "2. Every 1 hour"
    echo "3. Every 2 hours"
    echo "4. Every 4 hours"
    echo "5. Every 6 hours"
    echo "6. Every 12 hours"
    echo "7. Every 24 hours"
    echo ""
    read -rp "Enter your choice: " time_choice
    
    # Validate user input for restart time interval
    local restart_time
    case "$time_choice" in
        1) restart_time="*/30 * * * *" ;;
        2) restart_time="0 * * * *" ;;
        3) restart_time="0 */2 * * *" ;;
        4) restart_time="0 */4 * * *" ;;
        5) restart_time="0 */6 * * *" ;;
        6) restart_time="0 */12 * * *" ;;
        7) restart_time="0 0 * * *" ;;
        *)
            echo "Invalid choice. Please enter a number between 1 and 7."
            sleep 2
            return 1
            ;;
    esac

    # Remove existing cronjob created by this script
    delete_cron_job >/dev/null 2>&1
    
    # Path to reset file
    local reset_path="/root/easytier/reset.sh"
    
    # Add cron job to kill the running hexmesh processes
    cat << EOF > "$reset_path"
#!/bin/bash
pids=\$(pgrep easytier)
kill -9 \$pids 2>/dev/null || true
systemctl daemon-reload
systemctl restart $service_name
EOF

    # Make it executable
    chmod +x "$reset_path"
    
    # Save existing crontab to a temporary file
    crontab -l >/tmp/crontab.tmp 2>/dev/null || touch /tmp/crontab.tmp

    # Append the new cron job to the temporary file
    echo "$restart_time $reset_path #$service_name" >> /tmp/crontab.tmp

    # Install the modified crontab from the temporary file
    crontab /tmp/crontab.tmp

    # Remove the temporary file
    rm -f /tmp/crontab.tmp
    
    echo ""
    echo "✓ Cron-job added successfully to restart the service '$service_name'"
    sleep 2
}

delete_cron_job() {
    clear_screen
    print_banner
    print_header "Delete Cron Job"
    
    local service_name="hexmesh.service"
    local reset_path="/root/easytier/reset.sh"
    
    crontab -l 2>/dev/null | grep -v "#$service_name" | crontab - 2>/dev/null || true
    rm -f "$reset_path" >/dev/null 2>&1
    
    echo "✓ Cron job for $service_name deleted successfully"
    sleep 2
}

set_cronjob() {
    clear_screen
    print_banner
    print_header "Cron Job Management"
   	
    echo "Select your option:"
    echo "1) Add a new cronjob"
    echo "2) Delete existing cronjob"
    echo "3) Return..."
    echo ""
    read -rp "Select your option [1-3]: " choice
   	
    case "$choice" in 
        1) add_cron_job ;;
        2) delete_cron_job ;;
        3) return 0 ;;
        *) echo "Invalid option!" && sleep 1 && return 1 ;;
    esac
}

check_core_status() {
    local DEST_DIR="/root/easytier"
    local FILES=("easytier-core" "easytier-cli")
    
    if [ -d "$DEST_DIR" ]; then
        local all_files_exist=true
        for file in "${FILES[@]}"; do
            if [ ! -f "$DEST_DIR/$file" ]; then
                all_files_exist=false
                break
            fi
        done
        
        if [ "$all_files_exist" = true ]; then
            echo "✓ Hex Mesh Core v2.4.3 Installed"
            return 0
        fi
    fi
    
    echo "✗ Hex Mesh Core v2.4.3 not found"
    return 1
}

# New function to remove core
remove_hexmesh_core() {
    clear_screen
    print_banner
    print_header "Remove Hex Mesh Core"
    
    if [[ ! -d '/root/easytier' ]]; then
        echo "✗ Hex Mesh directory not found"
        sleep 2
        return 1
    fi
    
    rm -rf /root/easytier >/dev/null 2>&1
    echo "✓ Hex Mesh core deleted successfully"
    sleep 2
}
# Function to display menu
display_menu() {
    clear_screen
    print_banner
    
    # Status
    echo "============================================================"
    echo "Status: $(check_core_status)"
    echo "============================================================"
    echo ""
    
    # Network Section
    echo "Network Management"
    echo "  [1] Connect        • Setup mesh network"
    echo "  [2] Peers          • View connections"
    echo ""
    
    # Service Section
    echo "Service Management"
    echo "  [3] Secret         • Show credentials"
    echo "  [4] Status         • Service health"
    echo "  [5] Cron           • Schedule restart"
    echo "  [6] Restart        • Manual restart"
    echo ""
    
    # Advanced Section
    echo "Advanced"
    echo "  [7] Stop           • Stop service"
    echo "  [8] Remove         • Remove core"
    echo ""
    
    echo "[0] Exit"
    echo ""
}


# Function to read user input
read_option() {
    read -rp "Enter your choice: " choice 
    
    case "$choice" in
        1) connect_network_pool ;;
        2) display_peers ;;
        3) show_network_secret ;;
        4) view_service_status ;;
        5) set_cronjob ;;
        6) restart_hexmesh_service ;;
        7) remove_hexmesh_service ;;
        8) remove_hexmesh_core ;;
        0) 
            echo ""
            echo "Thanks for using Hex Mesh!"
            exit 0 
            ;;
        *) 
            echo "✗ Invalid option"
            sleep 1 
            ;;
    esac
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    abort "This script must be run as root"
fi

# Main script
while true; do
    display_menu
    read_option
done
