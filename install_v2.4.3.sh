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
  echo -e "${SEP}║   ${MAGENTA}${BOLD}██╗  ██╗███████╗██╗  ██╗   ${CYAN} ███╗   ███╗███████╗███████╗██╗  ██╗   ${SEP}║${RESET}"
  echo -e "${SEP}║   ${MAGENTA}${BOLD}██║  ██║██╔════╝╚██╗██╔╝   ${CYAN} ████╗ ████║██╔════╝██╔════╝██║  ██║   ${SEP}║${RESET}"
  echo -e "${SEP}║   ${MAGENTA}${BOLD}███████║█████╗   ╚███╔╝    ${CYAN} ██╔████╔██║█████╗  ███████╗███████║   ${SEP}║${RESET}"
  echo -e "${SEP}║   ${MAGENTA}${BOLD}██╔══██║██╔══╝   ██╔██╗    ${CYAN} ██║╚██╔╝██║██╔══╝  ╚════██║██╔══██║   ${SEP}║${RESET}"
  echo -e "${SEP}║   ${MAGENTA}${BOLD}██║  ██║███████╗██╔╝ ██╗   ${CYAN} ██║ ╚═╝ ██║███████╗███████║██║  ██║   ${SEP}║${RESET}"
  echo -e "${SEP}║   ${MAGENTA}${BOLD}╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ${CYAN} ╚═╝     ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝   ${SEP}║${RESET}"
  echo -e "${SEP}║                                                                    ║${RESET}"
  echo -e "${SEP}╚════════════════════════════════════════════════════════════════════╝${RESET}"
  echo -e "${GRAY} Version: 2.4.3 | GitHub: github.com/mordak-95/hex-mesh${RESET}"
  echo -e "${GRAY} Advanced VPN Mesh Network Solution${RESET}\n"
}

install_easytier() {
    local DEST_DIR="/root/easytier"
    local FILES=("easytier-core" "easytier-cli" "easytier-web" "easytier-web-embed")
    
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
    
    echo "Configuration Notes:"
    echo "• Leave peer addresses blank to enable reverse mode"
    echo "• WS and WSS modes are not recommended for Iran's network environment"
    echo "• Try disabling multi-thread mode if your mesh network is unstable"
    echo "• UDP mode is more stable than TCP mode"
    echo ""
    
    read -rp "Enter Peer IPv4/IPv6 Addresses (separate multiple addresses by ','): " PEER_ADDRESSES
    
    read -rp "Enter Local IPv4 Address (e.g., 10.144.144.1): " IP_ADDRESS
    [[ -z "$IP_ADDRESS" ]] && abort "Local IP address cannot be empty"
    
    read -rp "Enter Hostname (e.g., Hetzner): " HOSTNAME
    [[ -z "$HOSTNAME" ]] && abort "Hostname cannot be empty"
    
    read -rp "Enter Tunnel Port (Default 2090): " PORT
    PORT=${PORT:-2090}
    
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
    read -rp "Enable encryption? (yes/no): " ENCRYPTION_CHOICE
    case "$ENCRYPTION_CHOICE" in
        [Nn]*) 
            ENCRYPTION_OPTION="--disable-encryption"
            echo "Encryption is disabled"
            ;;
        *) 
            ENCRYPTION_OPTION=""
            echo "Encryption is enabled"
            ;;
    esac
    
    echo ""
    read -rp "Enable multi-thread? (yes/no): " MULTI_THREAD
    case "$MULTI_THREAD" in
        [Nn]*) 
            MULTI_THREAD=""
            echo "Multi-thread is disabled"
            ;;
        *) 
            MULTI_THREAD="--multi-thread"
            echo "Multi-thread is enabled"
            ;;
    esac
    
    echo ""
    read -rp "Enable IPv6? (yes/no): " IPV6_MODE
    case "$IPV6_MODE" in
        [Nn]*) 
            IPV6_MODE="--disable-ipv6"
            echo "IPv6 is disabled"
            ;;
        *) 
            IPV6_MODE=""
            echo "IPv6 is enabled"
            ;;
    esac
    
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

display_routes() {
    clear_screen
    print_banner
    print_header "Network Routes"
    echo "Press Ctrl+C to return to main menu"
    echo ""
    watch -n1 "$EASY_CLIENT" route
}

peer_center() {
    clear_screen
    print_banner
    print_header "Peer Center"
    echo "Press Ctrl+C to return to main menu"
    echo ""
    watch -n1 "$EASY_CLIENT" peer-center
}

restart_easymesh_service() {
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

remove_easymesh_service() {
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

set_watchdog() {
    clear_screen
    print_banner
    print_header "Watchdog Management"
    
    view_watchdog_status
    echo ""
    echo "Select your option:"
    echo "1) Create watchdog service"
    echo "2) Stop & remove watchdog service"
    echo "3) View Logs"
    echo "4) Back"
    echo ""
    read -rp "Enter your choice: " CHOICE
    
    case "$CHOICE" in 
        1) start_watchdog ;;
        2) stop_watchdog ;;
        3) view_logs ;;
        4) return 0;;
        *) echo "Invalid option!" && sleep 1 && return 1;;
    esac
}

start_watchdog() {
    clear_screen
    print_banner
    print_header "Create Watchdog Service"
    
    echo "Important: You can check the status of the service"
    echo "and restart it if the latency is higher than a certain limit."
    echo "I recommend to run it only on one server and preferably outside (Kharej) server"
    echo ""
    
    read -rp "Enter the local IP address to monitor: " IP_ADDRESS
    read -rp "Enter the latency threshold in ms (200): " LATENCY_THRESHOLD
    read -rp "Enter the time between checks in seconds (8): " CHECK_INTERVAL
	
    stop_watchdog
    touch /etc/monitor.sh /etc/monitor.log >/dev/null 2>&1
    
    cat << EOF | tee /etc/monitor.sh > /dev/null
#!/bin/bash

# Configuration
IP_ADDRESS="$IP_ADDRESS"
LATENCY_THRESHOLD=$LATENCY_THRESHOLD
CHECK_INTERVAL=$CHECK_INTERVAL
SERVICE_NAME="hexmesh.service"
LOG_FILE="/etc/monitor.log"

# Function to restart the service
restart_service() {
    local restart_time=\$(date +"%Y-%m-%d %H:%M:%S")
    systemctl restart "\$SERVICE_NAME"
    if [ \$? -eq 0 ]; then
        echo "\$restart_time: Service \$SERVICE_NAME restarted successfully." >> "\$LOG_FILE"
    else
        echo "\$restart_time: Failed to restart service \$SERVICE_NAME." >> "\$LOG_FILE"
    fi
}

# Function to calculate average latency
calculate_average_latency() {
    local latencies=(\$(ping -c 3 -W 2 -i 0.2 "\$IP_ADDRESS" | grep 'time=' | sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p'))
    local total_latency=0
    local count=\${#latencies[@]}

    for latency in "\${latencies[@]}"; do
        total_latency=\$(echo "\$total_latency + \$latency" | bc)
    done

    if [ \$count -gt 0 ]; then
        local average_latency=\$(echo "scale=2; \$total_latency / \$count" | bc)
        echo \$average_latency
    else
        echo 0
    fi
}

# Main monitoring loop
while true; do
    # Calculate average latency
    AVG_LATENCY=\$(calculate_average_latency)
    
    if [ "\$AVG_LATENCY" == "0" ]; then
        echo "\$(date +"%Y-%m-%d %H:%M:%S"): Failed to ping \$IP_ADDRESS. Restarting service..." >> "\$LOG_FILE"
        restart_service
    else
        LATENCY_INT=\${AVG_LATENCY%.*}  # Convert latency to integer for comparison
        if [ "\$LATENCY_INT" -gt "\$LATENCY_THRESHOLD" ]; then
            echo "\$(date +"%Y-%m-%d %H:%M:%S"): Average latency \$AVG_LATENCY ms exceeds threshold of \$LATENCY_THRESHOLD ms. Restarting service..." >> "\$LOG_FILE"
            restart_service
        fi
    fi

    # Wait for the specified interval before checking again
    sleep "\$CHECK_INTERVAL"
done
EOF

    echo ""
    echo "Creating a service for watchdog"
    echo ""
    
    local WATCHDOG_SERVICE_FILE="/etc/systemd/system/hexmesh-watchdog.service"    
    cat > "$WATCHDOG_SERVICE_FILE" <<EOF
[Unit]
Description=Hex Mesh Watchdog Service
After=network.target

[Service]
ExecStart=/bin/bash /etc/monitor.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # Execute the script in the background
    systemctl daemon-reload >/dev/null 2>&1
    systemctl enable --now hexmesh-watchdog.service >/dev/null 2>&1
    
    echo ""
    echo "✓ Watchdog service started successfully"
    echo ""
    press_key
}

# Function to stop the watchdog
stop_watchdog() {
    local WATCHDOG_SERVICE_FILE="/etc/systemd/system/hexmesh-watchdog.service" 
    
    if [[ ! -f "$WATCHDOG_SERVICE_FILE" ]]; then
        echo "✗ Watchdog service does not exist"
        sleep 1
        return 1
    fi
    
    systemctl disable --now hexmesh-watchdog.service >/dev/null 2>&1
    rm -f /etc/monitor.sh /etc/monitor.log >/dev/null 2>&1 
    rm -f "$WATCHDOG_SERVICE_FILE" >/dev/null 2>&1 
    systemctl daemon-reload >/dev/null 2>&1
    echo "✓ Watchdog service stopped and removed successfully"
    sleep 2
}

view_watchdog_status() {
    if systemctl is-active --quiet "hexmesh-watchdog.service"; then
        echo "✓ Watchdog service is running"
    else
        echo "✗ Watchdog service is not running"
    fi
}

# Function to view logs
view_logs() {
    clear_screen
    print_banner
    print_header "Watchdog Logs"
    
    if [ -f /etc/monitor.log ]; then
        less +G /etc/monitor.log
    else
        echo "No logs found."
        press_key
    fi
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
    
    # Add cron job to kill the running easymesh processes
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
    local FILES=("easytier-core" "easytier-cli" "easytier-web" "easytier-web-embed")
    
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
remove_easymesh_core() {
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
    echo "  [1] Connect       • Setup mesh network"
    echo "  [2] Peers          • View connections"
    echo "  [3] Routes         • Network topology"
    echo "  [4] Center         • Peer management"
    echo ""
    
    # Service Section
    echo "Service Management"
    echo "  [5] Secret         • Show credentials"
    echo "  [6] Status         • Service health"
    echo "  [7] Watchdog       • Auto-restart"
    echo "  [8] Cron           • Schedule tasks"
    echo "  [9] Restart        • Manual restart"
    echo ""
    
    # Advanced Section
    echo "Advanced"
    echo "  [10] Remove        • Stop service"
    echo "  [11] Uninstall     • Remove core"
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
        3) display_routes ;;
        4) peer_center ;;
        5) show_network_secret ;;
        6) view_service_status ;;
        7) set_watchdog ;;
        8) set_cronjob ;;
        9) restart_easymesh_service ;;
        10) remove_easymesh_service ;;
        11) remove_easymesh_core ;;
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
