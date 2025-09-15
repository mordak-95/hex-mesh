#!/bin/bash

# EasyTier Management Script
# Simple script to manage EasyTier service

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SERVICE_NAME="easytier"
CONFIG_DIR="/opt/easytier/config"
INSTANCE_NAME="default"

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
    echo -e "${BLUE}    EasyTier Manager Script     ${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to show service status
show_status() {
    print_header
    print_status "EasyTier Service Status:"
    echo
    
    if systemctl is-active --quiet "${SERVICE_NAME}@${INSTANCE_NAME}"; then
        echo -e "${GREEN}● Service Status: RUNNING${NC}"
    else
        echo -e "${RED}● Service Status: STOPPED${NC}"
    fi
    
    if systemctl is-enabled --quiet "${SERVICE_NAME}@${INSTANCE_NAME}"; then
        echo -e "${GREEN}● Auto Start: ENABLED${NC}"
    else
        echo -e "${YELLOW}● Auto Start: DISABLED${NC}"
    fi
    
    echo
    print_status "Service Details:"
    systemctl status "${SERVICE_NAME}@${INSTANCE_NAME}" --no-pager -l
    
    echo
    print_status "Recent Logs:"
    journalctl -u "${SERVICE_NAME}@${INSTANCE_NAME}" --no-pager -n 10
}

# Function to start service
start_service() {
    print_header
    print_status "Starting EasyTier service..."
    
    if systemctl is-active --quiet "${SERVICE_NAME}@${INSTANCE_NAME}"; then
        print_warning "Service is already running"
    else
        systemctl start "${SERVICE_NAME}@${INSTANCE_NAME}"
        sleep 2
        
        if systemctl is-active --quiet "${SERVICE_NAME}@${INSTANCE_NAME}"; then
            print_status "Service started successfully"
        else
            print_error "Failed to start service"
            systemctl status "${SERVICE_NAME}@${INSTANCE_NAME}" --no-pager
            exit 1
        fi
    fi
}

# Function to stop service
stop_service() {
    print_header
    print_status "Stopping EasyTier service..."
    
    if ! systemctl is-active --quiet "${SERVICE_NAME}@${INSTANCE_NAME}"; then
        print_warning "Service is already stopped"
    else
        systemctl stop "${SERVICE_NAME}@${INSTANCE_NAME}"
        print_status "Service stopped successfully"
    fi
}

# Function to restart service
restart_service() {
    print_header
    print_status "Restarting EasyTier service..."
    
    systemctl restart "${SERVICE_NAME}@${INSTANCE_NAME}"
    sleep 2
    
    if systemctl is-active --quiet "${SERVICE_NAME}@${INSTANCE_NAME}"; then
        print_status "Service restarted successfully"
    else
        print_error "Failed to restart service"
        systemctl status "${SERVICE_NAME}@${INSTANCE_NAME}" --no-pager
        exit 1
    fi
}

# Function to enable auto-start
enable_autostart() {
    print_header
    print_status "Enabling EasyTier auto-start..."
    
    systemctl enable "${SERVICE_NAME}@${INSTANCE_NAME}"
    print_status "Auto-start enabled"
}

# Function to disable auto-start
disable_autostart() {
    print_header
    print_status "Disabling EasyTier auto-start..."
    
    systemctl disable "${SERVICE_NAME}@${INSTANCE_NAME}"
    print_status "Auto-start disabled"
}

# Function to show logs
show_logs() {
    print_header
    print_status "EasyTier Service Logs (Press Ctrl+C to exit):"
    echo
    
    journalctl -u "${SERVICE_NAME}@${INSTANCE_NAME}" -f
}

# Function to show network info
show_network_info() {
    print_header
    print_status "EasyTier Network Information:"
    echo
    
    if command -v easytier-cli >/dev/null 2>&1; then
        echo -e "${GREEN}Connected Peers:${NC}"
        easytier-cli peer
        echo
        
        echo -e "${GREEN}Routing Table:${NC}"
        easytier-cli route
        echo
        
        echo -e "${GREEN}Node Information:${NC}"
        easytier-cli node
    else
        print_error "easytier-cli not found. Make sure EasyTier is properly installed."
    fi
}

# Function to edit configuration
edit_config() {
    print_header
    print_status "Opening EasyTier configuration for editing..."
    
    local config_file="${CONFIG_DIR}/${INSTANCE_NAME}.conf"
    
    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi
    
    # Check if nano is available
    if command -v nano >/dev/null 2>&1; then
        nano "$config_file"
    elif command -v vim >/dev/null 2>&1; then
        vim "$config_file"
    else
        print_error "No text editor found. Please install nano or vim."
        exit 1
    fi
    
    echo
    print_warning "Configuration file edited. Restart the service to apply changes."
    read -p "Do you want to restart the service now? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        restart_service
    fi
}

# Function to show configuration
show_config() {
    print_header
    print_status "EasyTier Configuration:"
    echo
    
    local config_file="${CONFIG_DIR}/${INSTANCE_NAME}.conf"
    
    if [[ -f "$config_file" ]]; then
        cat "$config_file"
    else
        print_error "Configuration file not found: $config_file"
    fi
}

# Function to uninstall EasyTier
uninstall() {
    print_header
    print_warning "This will completely remove EasyTier from your system."
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Uninstall cancelled"
        exit 0
    fi
    
    print_status "Stopping EasyTier service..."
    systemctl stop "${SERVICE_NAME}@${INSTANCE_NAME}" 2>/dev/null || true
    systemctl disable "${SERVICE_NAME}@${INSTANCE_NAME}" 2>/dev/null || true
    
    print_status "Removing systemd service..."
    rm -f "/etc/systemd/system/${SERVICE_NAME}@.service"
    systemctl daemon-reload
    
    print_status "Removing EasyTier files..."
    rm -rf "/opt/easytier"
    rm -f "/usr/local/bin/easytier-cli"
    
    print_status "Removing firewall rules..."
    if command -v ufw >/dev/null 2>&1; then
        ufw delete allow 11010/tcp 2>/dev/null || true
        ufw delete allow 11010/udp 2>/dev/null || true
        ufw delete allow 11011/tcp 2>/dev/null || true
        ufw delete allow 11012/tcp 2>/dev/null || true
        ufw delete allow 11013/udp 2>/dev/null || true
    fi
    
    print_status "EasyTier has been completely removed from your system."
}

# Function to show help
show_help() {
    print_header
    echo "EasyTier Management Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  status      Show service status and recent logs"
    echo "  start       Start EasyTier service"
    echo "  stop        Stop EasyTier service"
    echo "  restart     Restart EasyTier service"
    echo "  enable      Enable auto-start on boot"
    echo "  disable     Disable auto-start on boot"
    echo "  logs        Show live service logs"
    echo "  info        Show network information (peers, routes, node)"
    echo "  config      Show current configuration"
    echo "  edit        Edit configuration file"
    echo "  uninstall   Completely remove EasyTier"
    echo "  help        Show this help message"
    echo
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 restart"
    echo "  $0 logs"
    echo "  $0 edit"
}

# Main function
main() {
    case "${1:-help}" in
        status)
            show_status
            ;;
        start)
            check_root
            start_service
            ;;
        stop)
            check_root
            stop_service
            ;;
        restart)
            check_root
            restart_service
            ;;
        enable)
            check_root
            enable_autostart
            ;;
        disable)
            check_root
            disable_autostart
            ;;
        logs)
            show_logs
            ;;
        info)
            show_network_info
            ;;
        config)
            show_config
            ;;
        edit)
            check_root
            edit_config
            ;;
        uninstall)
            check_root
            uninstall
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
