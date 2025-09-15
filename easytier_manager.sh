#!/bin/bash

# EasyTier Network Manager
# Helper script for managing EasyTier mesh networks

RED_COLOR='\e[1;31m'
GREEN_COLOR='\e[1;32m'
YELLOW_COLOR='\e[1;33m'
BLUE_COLOR='\e[1;34m'
PINK_COLOR='\e[1;35m'
CYAN_COLOR='\e[1;36m'
RES='\e[0m'

INSTALL_PATH='/opt/easytier'

# Check if EasyTier is installed
check_installation() {
    if [ ! -f "$INSTALL_PATH/easytier-core" ]; then
        echo -e "${RED_COLOR}EasyTier is not installed!${RES}"
        echo "Please run the installer first: ./easytier_installer.sh"
        exit 1
    fi
}

# Show network status
show_status() {
    echo -e "${CYAN_COLOR}╔══════════════════════════════════════════════════════════════╗${RES}"
    echo -e "${CYAN_COLOR}║                    Network Status                          ║${RES}"
    echo -e "${CYAN_COLOR}╚══════════════════════════════════════════════════════════════╝${RES}\n"
    
    # Service status
    echo -e "${BLUE_COLOR}Service Status:${RES}"
    if systemctl is-active --quiet easytier@default 2>/dev/null; then
        echo -e "  ${GREEN_COLOR}✓ EasyTier service is running${RES}"
    else
        echo -e "  ${RED_COLOR}✗ EasyTier service is not running${RES}"
    fi
    
    echo
    
    # Node information
    echo -e "${BLUE_COLOR}Local Node Information:${RES}"
    if command -v easytier-cli >/dev/null 2>&1; then
        easytier-cli node 2>/dev/null || echo -e "  ${YELLOW_COLOR}Unable to get node information${RES}"
    else
        echo -e "  ${YELLOW_COLOR}easytier-cli not found${RES}"
    fi
    
    echo
    
    # Connected peers
    echo -e "${BLUE_COLOR}Connected Peers:${RES}"
    if command -v easytier-cli >/dev/null 2>&1; then
        easytier-cli peer 2>/dev/null || echo -e "  ${YELLOW_COLOR}Unable to get peer information${RES}"
    else
        echo -e "  ${YELLOW_COLOR}easytier-cli not found${RES}"
    fi
    
    echo
    
    # Network routes
    echo -e "${BLUE_COLOR}Network Routes:${RES}"
    if command -v easytier-cli >/dev/null 2>&1; then
        easytier-cli route 2>/dev/null || echo -e "  ${YELLOW_COLOR}Unable to get route information${RES}"
    else
        echo -e "  ${YELLOW_COLOR}easytier-cli not found${RES}"
    fi
}

# Add new peer
add_peer() {
    echo -e "${CYAN_COLOR}Add New Peer to Network${RES}\n"
    
    read -p "Enter peer IP address: " peer_ip
    if [[ ! $peer_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED_COLOR}Invalid IP address format${RES}"
        return 1
    fi
    
    read -p "Enter peer port (default: 11010): " peer_port
    peer_port=${peer_port:-11010}
    
    # Add peer to config
    config_file="$INSTALL_PATH/config/default.conf"
    if [ -f "$config_file" ]; then
        # Check if peer already exists
        if grep -q "uri = \"tcp://$peer_ip:$peer_port\"" "$config_file"; then
            echo -e "${YELLOW_COLOR}Peer already exists in configuration${RES}"
            return 0
        fi
        
        # Add peer before network_identity section
        sed -i "/\[network_identity\]/i [[peer]]\nuri = \"tcp://$peer_ip:$peer_port\"\n" "$config_file"
        
        echo -e "${GREEN_COLOR}✓ Peer added to configuration${RES}"
        echo -e "${BLUE_COLOR}Restarting service to apply changes...${RES}"
        
        systemctl restart easytier@default
        echo -e "${GREEN_COLOR}✓ Service restarted${RES}"
    else
        echo -e "${RED_COLOR}Configuration file not found${RES}"
        return 1
    fi
}

# Remove peer
remove_peer() {
    echo -e "${CYAN_COLOR}Remove Peer from Network${RES}\n"
    
    read -p "Enter peer IP address to remove: " peer_ip
    if [[ ! $peer_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED_COLOR}Invalid IP address format${RES}"
        return 1
    fi
    
    config_file="$INSTALL_PATH/config/default.conf"
    if [ -f "$config_file" ]; then
        # Remove peer from config
        sed -i "/\[\[peer\]\]/,/uri = \"tcp:\/\/$peer_ip:/d" "$config_file"
        
        echo -e "${GREEN_COLOR}✓ Peer removed from configuration${RES}"
        echo -e "${BLUE_COLOR}Restarting service to apply changes...${RES}"
        
        systemctl restart easytier@default
        echo -e "${GREEN_COLOR}✓ Service restarted${RES}"
    else
        echo -e "${RED_COLOR}Configuration file not found${RES}"
        return 1
    fi
}

# Test connectivity
test_connectivity() {
    echo -e "${CYAN_COLOR}Test Network Connectivity${RES}\n"
    
    if command -v easytier-cli >/dev/null 2>&1; then
        echo -e "${BLUE_COLOR}Getting peer list...${RES}"
        peers=$(easytier-cli peer 2>/dev/null | grep -E "^\|.*\|.*\|.*\|.*\|.*\|.*\|.*\|.*\|.*\|.*\|.*\|.*\|.*\|" | tail -n +3 | head -n -1)
        
        if [ -z "$peers" ]; then
            echo -e "${YELLOW_COLOR}No peers found to test${RES}"
            return 0
        fi
        
        echo -e "${BLUE_COLOR}Testing connectivity to peers...${RES}\n"
        
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                ip=$(echo "$line" | awk -F'|' '{print $2}' | xargs)
                hostname=$(echo "$line" | awk -F'|' '{print $3}' | xargs)
                
                if [ -n "$ip" ] && [ "$ip" != "ipv4" ]; then
                    echo -n "Testing $hostname ($ip): "
                    if ping -c 1 -W 3 "$ip" >/dev/null 2>&1; then
                        echo -e "${GREEN_COLOR}✓ Reachable${RES}"
                    else
                        echo -e "${RED_COLOR}✗ Unreachable${RES}"
                    fi
                fi
            fi
        done <<< "$peers"
    else
        echo -e "${RED_COLOR}easytier-cli not found${RES}"
        return 1
    fi
}

# Show configuration
show_config() {
    echo -e "${CYAN_COLOR}Current Configuration${RES}\n"
    
    config_file="$INSTALL_PATH/config/default.conf"
    if [ -f "$config_file" ]; then
        cat "$config_file"
    else
        echo -e "${RED_COLOR}Configuration file not found${RES}"
    fi
}

# Edit configuration
edit_config() {
    echo -e "${CYAN_COLOR}Edit Configuration${RES}\n"
    
    config_file="$INSTALL_PATH/config/default.conf"
    if [ -f "$config_file" ]; then
        echo -e "${BLUE_COLOR}Opening configuration file for editing...${RES}"
        echo -e "${YELLOW_COLOR}Note: After editing, restart the service to apply changes${RES}\n"
        
        if command -v nano >/dev/null 2>&1; then
            nano "$config_file"
        elif command -v vim >/dev/null 2>&1; then
            vim "$config_file"
        elif command -v vi >/dev/null 2>&1; then
            vi "$config_file"
        else
            echo -e "${RED_COLOR}No text editor found. Please install nano, vim, or vi${RES}"
            return 1
        fi
        
        echo -e "\n${BLUE_COLOR}Restart service to apply changes? (y/N): ${RES}"
        read -r restart
        if [[ $restart =~ ^[Yy]$ ]]; then
            systemctl restart easytier@default
            echo -e "${GREEN_COLOR}✓ Service restarted${RES}"
        fi
    else
        echo -e "${RED_COLOR}Configuration file not found${RES}"
    fi
}

# Service management
manage_service() {
    echo -e "${CYAN_COLOR}Service Management${RES}\n"
    
    echo "1) Start service"
    echo "2) Stop service"
    echo "3) Restart service"
    echo "4) Enable auto-start"
    echo "5) Disable auto-start"
    echo "6) View service status"
    echo "7) View service logs"
    echo
    
    read -p "Choose an option (1-7): " choice
    
    case $choice in
        1)
            systemctl start easytier@default
            echo -e "${GREEN_COLOR}✓ Service started${RES}"
            ;;
        2)
            systemctl stop easytier@default
            echo -e "${GREEN_COLOR}✓ Service stopped${RES}"
            ;;
        3)
            systemctl restart easytier@default
            echo -e "${GREEN_COLOR}✓ Service restarted${RES}"
            ;;
        4)
            systemctl enable easytier@default
            echo -e "${GREEN_COLOR}✓ Auto-start enabled${RES}"
            ;;
        5)
            systemctl disable easytier@default
            echo -e "${GREEN_COLOR}✓ Auto-start disabled${RES}"
            ;;
        6)
            systemctl status easytier@default
            ;;
        7)
            journalctl -u easytier@default -f
            ;;
        *)
            echo -e "${RED_COLOR}Invalid option${RES}"
            ;;
    esac
}

# Show help
show_help() {
    echo -e "${GREEN_COLOR}EasyTier Network Manager Help${RES}\n"
    echo "Usage: ./easytier_manager.sh [command]"
    echo
    echo "Commands:"
    echo "  status     Show network status and information"
    echo "  add-peer   Add a new peer to the network"
    echo "  remove-peer Remove a peer from the network"
    echo "  test       Test connectivity to peers"
    echo "  config     Show current configuration"
    echo "  edit       Edit configuration file"
    echo "  service    Manage EasyTier service"
    echo "  help       Show this help message"
    echo
    echo "Examples:"
    echo "  ./easytier_manager.sh status"
    echo "  ./easytier_manager.sh add-peer"
    echo "  ./easytier_manager.sh test"
}

# Main menu
show_menu() {
    while true; do
        clear
        echo -e "${CYAN_COLOR}"
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║                 EasyTier Network Manager                    ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo -e "${RES}\n"
        
        echo "1) Show network status"
        echo "2) Add new peer"
        echo "3) Remove peer"
        echo "4) Test connectivity"
        echo "5) Show configuration"
        echo "6) Edit configuration"
        echo "7) Manage service"
        echo "8) Help"
        echo "9) Exit"
        echo
        
        read -p "Choose an option (1-9): " choice
        
        case $choice in
            1) show_status; read -p "Press Enter to continue..."; ;;
            2) add_peer; read -p "Press Enter to continue..."; ;;
            3) remove_peer; read -p "Press Enter to continue..."; ;;
            4) test_connectivity; read -p "Press Enter to continue..."; ;;
            5) show_config; read -p "Press Enter to continue..."; ;;
            6) edit_config; read -p "Press Enter to continue..."; ;;
            7) manage_service; read -p "Press Enter to continue..."; ;;
            8) show_help; read -p "Press Enter to continue..."; ;;
            9) echo -e "${GREEN_COLOR}Goodbye!${RES}"; exit 0; ;;
            *) echo -e "${RED_COLOR}Invalid option${RES}"; sleep 2; ;;
        esac
    done
}

# Main function
main() {
    check_installation
    
    if [ $# -eq 0 ]; then
        show_menu
    else
        case $1 in
            status) show_status ;;
            add-peer) add_peer ;;
            remove-peer) remove_peer ;;
            test) test_connectivity ;;
            config) show_config ;;
            edit) edit_config ;;
            service) manage_service ;;
            help) show_help ;;
            *) echo -e "${RED_COLOR}Unknown command: $1${RES}"; show_help ;;
        esac
    fi
}

# Run main function
main "$@"
