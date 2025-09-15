#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   sleep 1
   exit 1
fi


#color codes
GREEN="\033[0;32m"
CYAN="\033[0;36m"
WHITE="\033[1;37m"
RESET="\033[0m"
MAGENTA="\033[0;35m"


# just press key to continue
press_key(){
 read -p "Press Enter to continue..."
}


# Define a function to colorize text
colorize() {
    local color="$1"
    local text="$2"
    local style="${3:-normal}"
    
    # Define ANSI color codes
    local black="\033[30m"
    local red="\033[31m"
    local green="\033[32m"
    local yellow="\033[33m"
    local blue="\033[34m"
    local magenta="\033[35m"
    local cyan="\033[36m"
    local white="\033[37m"
    local reset="\033[0m"
    
    # Define ANSI style codes
    local normal="\033[0m"
    local bold="\033[1m"
    local underline="\033[4m"
    # Select color code
    local color_code
    case $color in
        black) color_code=$black ;;
        red) color_code=$red ;;
        green) color_code=$green ;;
        yellow) color_code=$yellow ;;
        blue) color_code=$blue ;;
        magenta) color_code=$magenta ;;
        cyan) color_code=$cyan ;;
        white) color_code=$white ;;
        *) color_code=$reset ;;  # Default case, no color
    esac
    # Select style code
    local style_code
    case $style in
        bold) style_code=$bold ;;
        underline) style_code=$underline ;;
        normal | *) style_code=$normal ;;  # Default case, normal text
    esac

    # Print the colored and styled text
    echo -e "${style_code}${color_code}${text}${reset}"
}

install_easytier() {
    # Define the directory and files
    DEST_DIR="/root/easytier"
    FILE1="easytier-core"
    FILE2="easytier-cli"
    FILE3="easytier-web"
    FILE4="easytier-web-embed"

    # Version 2.4.3 URLs
    URL_X86="https://github.com/mordak-95/hex-mesh/raw/main/core/v2.4.3/easytier-linux-x86_64/"
    URL_ARM_SOFT="https://github.com/mordak-95/hex-mesh/raw/main/core/v2.4.3/easytier-linux-armv7/"              
    URL_ARM_HARD="https://github.com/mordak-95/hex-mesh/raw/main/core/v2.4.3/easytier-linux-armv7hf/"
    
    # Check if the directory exists
    if [ -d "$DEST_DIR" ]; then    
        # Check if the files exist
        if [ -f "$DEST_DIR/$FILE1" ] && [ -f "$DEST_DIR/$FILE2" ] && [ -f "$DEST_DIR/$FILE3" ] && [ -f "$DEST_DIR/$FILE4" ]; then
            colorize green "EasyMesh Core v2.4.3 Installed" bold
            return 0
        fi
    fi
    
    # Detect the system architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        URL=$URL_X86
    elif [ "$ARCH" = "armv7l" ] || [ "$ARCH" = "aarch64" ]; then
        if [ "$(ldd /bin/ls | grep -c 'armhf')" -eq 1 ]; then
            URL=$URL_ARM_HARD
        else
            URL=$URL_ARM_SOFT
        fi
    else
        colorize red "Unsupported architecture: $ARCH\n" bold
        return 1
    fi


    mkdir -p $DEST_DIR &> /dev/null
    colorize yellow "Downloading EasyMesh Core v2.4.3...\n"
    curl -Ls "$URL/easytier-cli" -o "$DEST_DIR/easytier-cli"
    curl -Ls "$URL/easytier-core" -o "$DEST_DIR/easytier-core"
    curl -Ls "$URL/easytier-web" -o "$DEST_DIR/easytier-web"
    curl -Ls "$URL/easytier-web-embed" -o "$DEST_DIR/easytier-web-embed"


    if [ -f "$DEST_DIR/$FILE1" ] && [ -f "$DEST_DIR/$FILE2" ] && [ -f "$DEST_DIR/$FILE3" ] && [ -f "$DEST_DIR/$FILE4" ]; then
    	chmod +x "$DEST_DIR/easytier-cli"
    	chmod +x "$DEST_DIR/easytier-core"
    	chmod +x "$DEST_DIR/easytier-web"
    	chmod +x "$DEST_DIR/easytier-web-embed"
        colorize green "EasyMesh Core v2.4.3 Installed Successfully...\n" bold
        sleep 1
        return 0
    else
        colorize red "Failed to install EasyMesh Core v2.4.3...\n" bold
        exit 1
    fi
}



# Call the function
install_easytier

generate_random_secret() {
    openssl rand -hex 6
}

#Var
EASY_CLIENT='/root/easytier/easytier-cli'
SERVICE_FILE="/etc/systemd/system/easymesh.service"
    
connect_network_pool(){
	clear
	colorize cyan "Connect to the Mesh Network" bold 
	echo 
	colorize yellow "Leave the peer addresses blank to enable reverse mode.
Ws and wss modes are not recommended for iran's network environment.
Try disable multi-thread mode if your mesh network is unstable.
UDP mode is more stable rather than tcp mode.
	"
	echo
    read -p "[-] Enter Peer IPv4/IPv6 Addresses (separate multiple addresses by ','): " PEER_ADDRESSES
    
    read -p "[*] Enter Local IPv4 Address (e.g., 10.144.144.1): " IP_ADDRESS
    if [ -z $IP_ADDRESS ]; then
    	colorize red "Null value. aborting..."
    	sleep 2
    	return 1
    fi
    
    read -r -p "[*] Enter Hostname (e.g., Hetnzer): " HOSTNAME
    if [ -z $HOSTNAME ]; then
    	colorize red "Null value. aborting..."
    	sleep 2
    	return 1
    fi
    
    read -p "[-] Enter Tunnel Port (Default 2090): " PORT
    if [ -z $PORT ]; then
    	colorize red "Default port is 2090..."
    	PORT='2090'
    fi
    
	echo ''
    NETWORK_SECRET=$(generate_random_secret)
    colorize cyan "[✓] Generated Network Secret: $NETWORK_SECRET" bold
    while true; do
    read -p "[*] Enter Network Secret (recommend using a strong password): " NETWORK_SECRET
    if [[ -n $NETWORK_SECRET ]]; then
        break
    else
        colorize red "Network secret cannot be empty. Please enter a valid secret.\n"
    fi
	done
	

	echo ''
    colorize green "[-] Select Default Protocol:" bold
    echo "1) tcp"
    echo "2) udp"
    echo "3) ws"
    echo "4) wss"
    read -p "[*] Select your desired protocol (e.g., 1 for tcp): " PROTOCOL_CHOICE
	
    case $PROTOCOL_CHOICE in
        1) DEFAULT_PROTOCOL="tcp" ;;
        2) DEFAULT_PROTOCOL="udp" ;;
        3) DEFAULT_PROTOCOL="ws" ;;
        4) DEFAULT_PROTOCOL="wss" ;;
        *) colorize red "Invalid choice. Defaulting to tcp." ; DEFAULT_PROTOCOL="tcp" ;;
    esac
	
	echo 
	read -p "[-] Enable encryption? (yes/no): " ENCRYPTION_CHOICE
	case $ENCRYPTION_CHOICE in
        [Nn]*)
        	ENCRYPTION_OPTION="--disable-encryption"
        	colorize yellow "Encryption is disabled"
       		 ;;
   		*)
       		ENCRYPTION_OPTION=""
       		colorize yellow "Encryption is enabled"
             ;;
	esac
	
	echo
	
	read -p "[-] Enable multi-thread? (yes/no): " MULTI_THREAD
	case $MULTI_THREAD in
        [Nn]*)
        	MULTI_THREAD=""
        	colorize yellow "Multi-thread is disabled"
       		 ;;
   		*)
       		MULTI_THREAD="--multi-thread"
       		colorize yellow "Multi-thread is enabled"
             ;;
	esac
	
	echo
	
	read -p "[-] Enable IPv6? (yes/no): " IPV6_MODE
	case $IPV6_MODE in
        [Nn]*)
        	IPV6_MODE="--disable-ipv6"
        	colorize yellow "IPv6 is disabled"
       		 ;;
   		*)
       		IPV6_MODE=""
       		colorize yellow "IPv6 is enabled"
             ;;
	esac
	
	echo
	
	read -p "[-] Enable Web Interface? (yes/no): " ENABLE_WEB
	case $ENABLE_WEB in
        [Yy]*)
        	ENABLE_WEB="yes"
        	colorize yellow "Web Interface will be enabled on port 9090"
       		 ;;
   		*)
       		ENABLE_WEB="no"
       		colorize yellow "Web Interface is disabled"
             ;;
	esac
	
	echo
    
    IFS=',' read -ra ADDR_ARRAY <<< "$PEER_ADDRESSES"
    PROCESSED_ADDRESSES=()
    for ADDRESS in "${ADDR_ARRAY[@]}"; do
        ADDRESS=$(echo $ADDRESS | xargs)
        
        if [[ "$ADDRESS" == *:* ]]; then
            if [[ "$ADDRESS" != \[*\] ]]; then
                ADDRESS="[$ADDRESS]"
            fi
        fi
    
        if [ ! -z "$ADDRESS" ]; then
            PROCESSED_ADDRESSES+=("${DEFAULT_PROTOCOL}://${ADDRESS}:${PORT}")
        fi
    done
    
    JOINED_ADDRESSES=$(IFS=' '; echo "${PROCESSED_ADDRESSES[*]}")
    
    if [ ! -z "$JOINED_ADDRESSES" ]; then
        PEER_ADDRESS="--peers ${JOINED_ADDRESSES}"
    fi
    
    LISTENERS="--listeners ${DEFAULT_PROTOCOL}://[::]:${PORT} ${DEFAULT_PROTOCOL}://0.0.0.0:${PORT}"
    
    SERVICE_FILE="/etc/systemd/system/easymesh.service"
    
cat > $SERVICE_FILE <<EOF
[Unit]
Description=EasyMesh Network Service v2.4.3
After=network.target

[Service]
ExecStart=/root/easytier/easytier-core -i $IP_ADDRESS $PEER_ADDRESS --hostname $HOSTNAME --network-secret $NETWORK_SECRET --default-protocol $DEFAULT_PROTOCOL $LISTENERS $MULTI_THREAD $ENCRYPTION_OPTION $IPV6_MODE
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd, enable and start the service
    sudo systemctl daemon-reload &> /dev/null
    sudo systemctl enable easymesh.service &> /dev/null
    sudo systemctl start easymesh.service &> /dev/null

    colorize green "EasyMesh Network Service v2.4.3 Started.\n" bold
    
    # Start web interface if enabled
    if [[ "$ENABLE_WEB" == "yes" ]]; then
        start_web_interface
    fi
    
	press_key
}

start_web_interface() {
    colorize yellow "Starting Web Interface on port 9090...\n" bold
    
    # Check if easytier-web-embed exists
    if [[ ! -f "/root/easytier/easytier-web-embed" ]]; then
        colorize red "easytier-web-embed file not found!\n" bold
        colorize yellow "Please make sure you have installed EasyMesh Core v2.4.3\n" bold
        return 1
    fi
    
    # Make sure it's executable
    chmod +x /root/easytier/easytier-web-embed
    
    # Create web interface service file
    WEB_SERVICE_FILE="/etc/systemd/system/easymesh-web.service"
    
cat > $WEB_SERVICE_FILE <<EOF
[Unit]
Description=EasyMesh Web Interface v2.4.3
After=network.target
Wants=easymesh.service

[Service]
Type=simple
ExecStart=/root/easytier/easytier-web-embed
Restart=on-failure
RestartSec=5
User=root
StandardOutput=journal
StandardError=journal
Environment=PORT=9090

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd, enable and start the web service
    colorize yellow "Reloading systemd daemon..." bold
    sudo systemctl daemon-reload
    
    colorize yellow "Enabling web service..." bold
    sudo systemctl enable easymesh-web.service
    
    colorize yellow "Starting web service..." bold
    sudo systemctl start easymesh-web.service
    
    # Wait a moment and check status
    sleep 2
    
    if systemctl is-active --quiet "easymesh-web.service"; then
        colorize green "Web Interface started successfully on port 9090\n" bold
        echo
        colorize cyan "Web Interface Information:" bold
        colorize yellow "Access the web interface at: http://localhost:9090" bold
        colorize yellow "Or use your server's public IP: http://YOUR_SERVER_IP:9090" bold
        echo
    else
        colorize red "Failed to start Web Interface\n" bold
        colorize yellow "Checking logs for errors...\n" bold
        journalctl -u easymesh-web.service --no-pager -n 10
    fi
}

display_peers()
{	
	watch -n1 $EASY_CLIENT peer	
}
display_routes(){

	watch -n1 $EASY_CLIENT route	
}

peer_center(){

	watch -n1 $EASY_CLIENT peer-center	
}

restart_easymesh_service() {
	echo ''
	if [[ ! -f $SERVICE_FILE ]]; then
		colorize red "	EasyMesh service does not exists." bold
		sleep 1
		return 1
	fi
    colorize yellow "	Restarting EasyMesh service...\n" bold
    sudo systemctl restart easymesh.service &> /dev/null
    if [[ $? -eq 0 ]]; then
        colorize green "	EasyMesh service restarted successfully." bold
    else
        colorize red "	Failed to restart EasyMesh service." bold
    fi
    
    # Also restart web service if exists
    WEB_SERVICE_FILE="/etc/systemd/system/easymesh-web.service"
    if [[ -f $WEB_SERVICE_FILE ]]; then
        colorize yellow "	Restarting EasyMesh Web service...\n" bold
        sudo systemctl restart easymesh-web.service &> /dev/null
        if [[ $? -eq 0 ]]; then
            colorize green "	EasyMesh Web service restarted successfully." bold
        else
            colorize red "	Failed to restart EasyMesh Web service." bold
        fi
    fi
    
    echo ''
	 read -p "	Press Enter to continue..."
}

remove_easymesh_service() {
	echo
	if [[ ! -f $SERVICE_FILE ]]; then
		 colorize red "	EasyMesh service does not exists." bold
		 sleep 1
		 return 1
	fi
    
    # Stop and remove web service if exists
    WEB_SERVICE_FILE="/etc/systemd/system/easymesh-web.service"
    if [[ -f $WEB_SERVICE_FILE ]]; then
        colorize yellow "	Stopping EasyMesh Web service..." bold
        sudo systemctl stop easymesh-web.service &> /dev/null
        sudo systemctl disable easymesh-web.service &> /dev/null
        sudo rm $WEB_SERVICE_FILE &> /dev/null
        colorize green "	EasyMesh Web service removed successfully.\n"
    fi
    
    colorize yellow "	Stopping EasyMesh service..." bold
    sudo systemctl stop easymesh.service &> /dev/null
    if [[ $? -eq 0 ]]; then
        colorize green "	EasyMesh service stopped successfully.\n"
    else
        colorize red "	Failed to stop EasyMesh service.\n"
        sleep 2
        return 1
    fi

    colorize yellow "	Disabling EasyMesh service..." bold
    sudo systemctl disable easymesh.service &> /dev/null
    if [[ $? -eq 0 ]]; then
        colorize green "	EasyMesh service disabled successfully.\n"
    else
        colorize red "	Failed to disable EasyMesh service.\n"
        sleep 2
        return 1
    fi

    colorize yellow "	Removing EasyMesh service..." bold
    sudo rm /etc/systemd/system/easymesh.service &> /dev/null
    if [[ $? -eq 0 ]]; then
        colorize green "	EasyMesh service removed successfully.\n"
    else
        colorize red "	Failed to remove EasyMesh service.\n"
        sleep 2
        return 1
    fi

    colorize yellow "	Reloading systemd daemon..." bold
    sudo systemctl daemon-reload
    if [[ $? -eq 0 ]]; then
        colorize green "	Systemd daemon reloaded successfully.\n"
    else
        colorize red "	Failed to reload systemd daemon.\n"
        sleep 2
        return 1
    fi
    
 read -p "	Press Enter to continue..."
}

show_network_secret() {
	echo ''
    if [[ -f $SERVICE_FILE ]]; then
        NETWORK_SECRET=$(grep -oP '(?<=--network-secret )[^ ]+' $SERVICE_FILE)
        
        if [[ -n $NETWORK_SECRET ]]; then
            colorize cyan "	Network Secret Key: $NETWORK_SECRET" bold
        else
            colorize red "	Network Secret key not found" bold
        fi
    else
        colorize red "	EasyMesh service does not exists." bold
    fi
    echo ''
    read -p "	Press Enter to continue..."
   
    
}

show_web_interface_info() {
	echo ''
    WEB_SERVICE_FILE="/etc/systemd/system/easymesh-web.service"
    
    if [[ -f $WEB_SERVICE_FILE ]]; then
        if systemctl is-active --quiet "easymesh-web.service"; then
            colorize cyan "	Web Interface is running" bold
            colorize yellow "	Access the web interface at: http://localhost:9090" bold
            colorize yellow "	Or use your server's public IP: http://YOUR_SERVER_IP:9090" bold
        else
            colorize red "	Web Interface service exists but is not running" bold
            colorize yellow "	Try restarting the service" bold
        fi
    else
        colorize red "	Web Interface is not enabled" bold
        colorize yellow "	To enable web interface, reconfigure the network connection" bold
    fi
    echo ''
    read -p "	Press Enter to continue..."
}

manage_web_interface() {
    clear
    WEB_SERVICE_FILE="/etc/systemd/system/easymesh-web.service"
    
    echo
    colorize cyan "Web Interface Management" bold
    echo "---------------------------------------------"
    echo
    
    if [[ -f $WEB_SERVICE_FILE ]]; then
        if systemctl is-active --quiet "easymesh-web.service"; then
            colorize green "1) Stop Web Interface" bold
            colorize yellow "2) Restart Web Interface"
            colorize reset "3) Back"
            echo
            read -p "Enter your choice: " web_choice
            case $web_choice in
                1) 
                    colorize yellow "Stopping Web Interface..." bold
                    sudo systemctl stop easymesh-web.service &> /dev/null
                    if [[ $? -eq 0 ]]; then
                        colorize green "Web Interface stopped successfully." bold
                    else
                        colorize red "Failed to stop Web Interface." bold
                    fi
                    ;;
                2)
                    colorize yellow "Restarting Web Interface..." bold
                    sudo systemctl restart easymesh-web.service &> /dev/null
                    if [[ $? -eq 0 ]]; then
                        colorize green "Web Interface restarted successfully." bold
                    else
                        colorize red "Failed to restart Web Interface." bold
                    fi
                    ;;
                3) return 0 ;;
                *) colorize red "Invalid option!" bold ;;
            esac
        else
            colorize green "1) Start Web Interface" bold
            colorize yellow "2) Remove Web Interface"
            colorize reset "3) Back"
            echo
            read -p "Enter your choice: " web_choice
            case $web_choice in
                1) 
                    colorize yellow "Starting Web Interface..." bold
                    sudo systemctl start easymesh-web.service &> /dev/null
                    if [[ $? -eq 0 ]]; then
                        colorize green "Web Interface started successfully." bold
                        colorize yellow "Access at: http://localhost:9090" bold
                    else
                        colorize red "Failed to start Web Interface." bold
                    fi
                    ;;
                2)
                    colorize yellow "Removing Web Interface..." bold
                    sudo systemctl stop easymesh-web.service &> /dev/null
                    sudo systemctl disable easymesh-web.service &> /dev/null
                    sudo rm $WEB_SERVICE_FILE &> /dev/null
                    sudo systemctl daemon-reload &> /dev/null
                    colorize green "Web Interface removed successfully." bold
                    ;;
                3) return 0 ;;
                *) colorize red "Invalid option!" bold ;;
            esac
        fi
    else
        colorize green "1) Create Web Interface" bold
        colorize reset "2) Back"
        echo
        read -p "Enter your choice: " web_choice
        case $web_choice in
            1) 
                start_web_interface
                ;;
            2) return 0 ;;
            *) colorize red "Invalid option!" bold ;;
        esac
    fi
    
    echo
    read -p "Press Enter to continue..."
}

debug_web_interface() {
    clear
    WEB_SERVICE_FILE="/etc/systemd/system/easymesh-web.service"
    
    echo
    colorize cyan "Web Interface Debug Information" bold
    echo "============================================="
    echo
    
    # Check if web-embed file exists
    colorize yellow "1. Checking easytier-web-embed file..." bold
    if [[ -f "/root/easytier/easytier-web-embed" ]]; then
        colorize green "   ✓ easytier-web-embed file exists" bold
        ls -la /root/easytier/easytier-web-embed
    else
        colorize red "   ✗ easytier-web-embed file NOT found" bold
    fi
    echo
    
    # Check if web-embed is executable
    colorize yellow "2. Checking file permissions..." bold
    if [[ -x "/root/easytier/easytier-web-embed" ]]; then
        colorize green "   ✓ easytier-web-embed is executable" bold
    else
        colorize red "   ✗ easytier-web-embed is NOT executable" bold
        colorize yellow "   Fixing permissions..." bold
        chmod +x /root/easytier/easytier-web-embed
    fi
    echo
    
    # Check service file
    colorize yellow "3. Checking service file..." bold
    if [[ -f $WEB_SERVICE_FILE ]]; then
        colorize green "   ✓ Service file exists" bold
        echo "   Service file content:"
        cat $WEB_SERVICE_FILE
    else
        colorize red "   ✗ Service file NOT found" bold
    fi
    echo
    
    # Check service status
    colorize yellow "4. Checking service status..." bold
    if systemctl is-active --quiet "easymesh-web.service"; then
        colorize green "   ✓ Service is running" bold
    else
        colorize red "   ✗ Service is NOT running" bold
    fi
    
    if systemctl is-enabled --quiet "easymesh-web.service"; then
        colorize green "   ✓ Service is enabled" bold
    else
        colorize red "   ✗ Service is NOT enabled" bold
    fi
    echo
    
    # Check service logs
    colorize yellow "5. Checking service logs..." bold
    echo "   Recent logs:"
    journalctl -u easymesh-web.service --no-pager -n 20
    echo
    
    # Check if port is in use
    colorize yellow "6. Checking port 9090..." bold
    if netstat -tlnp | grep -q ":9090 "; then
        colorize green "   ✓ Port 9090 is in use" bold
        netstat -tlnp | grep ":9090 "
    else
        colorize red "   ✗ Port 9090 is NOT in use" bold
    fi
    echo
    
    # Try to run web-embed manually
    colorize yellow "7. Testing manual execution..." bold
    echo "   Trying to run: /root/easytier/easytier-web-embed --help"
    timeout 10 /root/easytier/easytier-web-embed --help 2>&1 || echo "   Command timed out or failed"
    echo
    
    # Check dependencies
    colorize yellow "8. Checking dependencies..." bold
    if command -v curl &> /dev/null; then
        colorize green "   ✓ curl is available" bold
    else
        colorize red "   ✗ curl is NOT available" bold
    fi
    
    if command -v systemctl &> /dev/null; then
        colorize green "   ✓ systemctl is available" bold
    else
        colorize red "   ✗ systemctl is NOT available" bold
    fi
    echo
    
    echo
    colorize cyan "Debug completed. Press Enter to continue..." bold
    read -p ""
}

test_web_embed_parameters() {
    clear
    echo
    colorize cyan "Testing easytier-web-embed Parameters" bold
    echo "============================================="
    echo
    
    if [[ ! -f "/root/easytier/easytier-web-embed" ]]; then
        colorize red "easytier-web-embed file not found!" bold
        return 1
    fi
    
    colorize yellow "Testing different parameter combinations..." bold
    echo
    
    # Test 1: No parameters
    colorize yellow "1. Testing with no parameters:" bold
    timeout 3 /root/easytier/easytier-web-embed 2>&1 | head -5 || echo "   Command timed out or failed"
    echo
    
    # Test 2: --help
    colorize yellow "2. Testing --help:" bold
    timeout 5 /root/easytier/easytier-web-embed --help 2>&1 || echo "   Command timed out or failed"
    echo
    
    # Test 3: Different port syntax
    colorize yellow "3. Testing different port syntaxes:" bold
    echo "   Testing: --port 9090"
    timeout 3 /root/easytier/easytier-web-embed --port 9090 2>&1 | head -3 || echo "   Failed"
    echo "   Testing: -p 9090"
    timeout 3 /root/easytier/easytier-web-embed -p 9090 2>&1 | head -3 || echo "   Failed"
    echo "   Testing: --listen 9090"
    timeout 3 /root/easytier/easytier-web-embed --listen 9090 2>&1 | head -3 || echo "   Failed"
    echo "   Testing: --bind 0.0.0.0:9090"
    timeout 3 /root/easytier/easytier-web-embed --bind 0.0.0.0:9090 2>&1 | head -3 || echo "   Failed"
    echo
    
    # Test 4: Environment variable
    colorize yellow "4. Testing with environment variable:" bold
    echo "   Testing: PORT=9090 ./easytier-web-embed"
    timeout 3 env PORT=9090 /root/easytier/easytier-web-embed 2>&1 | head -3 || echo "   Failed"
    echo
    
    echo
    colorize cyan "Parameter testing completed. Press Enter to continue..." bold
    read -p ""
}

view_service_status() {
	if [[ ! -f $SERVICE_FILE ]]; then
		 colorize red "	EasyMesh service does not exists." bold
		 sleep 1
		 return 1
	fi
	clear
    colorize cyan "EasyMesh Core Service Status:" bold
    sudo systemctl status easymesh.service
    
    WEB_SERVICE_FILE="/etc/systemd/system/easymesh-web.service"
    if [[ -f $WEB_SERVICE_FILE ]]; then
        echo
        colorize cyan "EasyMesh Web Service Status:" bold
        sudo systemctl status easymesh-web.service
    fi
    
    echo
    read -p "Press Enter to continue..."
}

set_watchdog(){
	clear
	view_watchdog_status
	echo "---------------------------------------------"
	echo 
	colorize cyan "Select your option:" bold
	colorize green "1) Create watchdog service"
	colorize red "2) Stop & remove watchdog service"
    colorize yellow "3) View Logs"
    colorize reset "4) Back"
    echo ''
    read -p "Enter your choice: " CHOICE
    case $CHOICE in 
    	1) start_watchdog ;;
    	2) stop_watchdog ;;
    	3) view_logs ;;
    	4) return 0;;
    	*) colorize red "Invalid option!" bold && sleep 1 && return 1;;
    esac

}

start_watchdog(){
	clear
	colorize cyan "Important: You can check the status of the service \nand restart it if the latency is higher than a certain limit. \nI recommend to run it only on one server and preferably outside (Kharej) server" bold
	echo ''
	
	read -p "Enter the local IP address to monitor: " IP_ADDRESS
	read -p "Enter the latency threshold in ms (200): " LATENCY_THRESHOLD
	read -p "Enter the time between checks in seconds (8): " CHECK_INTERVAL
	
	
	stop_watchdog
	touch /etc/monitor.sh /etc/monitor.log &> /dev/null
	
cat << EOF | sudo tee /etc/monitor.sh > /dev/null
#!/bin/bash

# Configuration
IP_ADDRESS="$IP_ADDRESS"
LATENCY_THRESHOLD=$LATENCY_THRESHOLD
CHECK_INTERVAL=$CHECK_INTERVAL
SERVICE_NAME="easymesh.service"
LOG_FILE="/etc/monitor.log"

# Function to restart the service
restart_service() {
    local restart_time=\$(date +"%Y-%m-%d %H:%M:%S")
    sudo systemctl restart "\$SERVICE_NAME"
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


	echo
	colorize yellow "Creating a service for watchdog" bold
	echo
    
SERVICE_FILE="/etc/systemd/system/easymesh-watchdog.service"    
cat > $SERVICE_FILE <<EOF
[Unit]
Description=EasyMesh Watchdog Service
After=network.target

[Service]
ExecStart=/bin/bash /etc/monitor.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

	# Execute the script in the background
    systemctl daemon-reload >/dev/null 2>&1
	systemctl enable --now easymesh-watchdog.service
	
    echo
    colorize green "Watchdog service started successfully" bold
    echo
press_key
}

# Function to stop the watchdog
stop_watchdog() {
	echo 
	SERVICE_FILE="/etc/systemd/system/easymesh-watchdog.service" 
	
	if [[ ! -f $SERVICE_FILE ]]; then
		 colorize red "Watchdog service does not exists." bold
		 sleep 1
		 return 1
	fi
	
    systemctl disable --now easymesh-watchdog.service &> /dev/null
    rm -f /etc/monitor.sh /etc/monitor.log &> /dev/null 
    rm -f "$SERVICE_FILE"  &> /dev/null 
    systemctl daemon-reload &> /dev/null
    colorize yellow "Watchdog service stopped and removed successfully" bold
    echo
    sleep 2
}

view_watchdog_status(){
	if systemctl is-active --quiet "easymesh-watchdog.service"; then
				colorize green "	Watchdog service is running" bold
			else
				colorize red "	Watchdog service is not running" bold
	fi		

}
# Function to view logs
view_logs() {
    if [ -f /etc/monitor.log ]; then
        less +G /etc/monitor.log
    else
    	echo ''
        colorize yellow "No logs found.\n" bold
        press_key
    fi
    
}


# Function to add cron-tab job
add_cron_job() {
	echo 

	local service_name="easymesh.service"
	
    # Prompt user to choose a restart time interval
    colorize cyan "Select the restart time interval:" bold
    echo
    echo "1. Every 30th minute"
    echo "2. Every 1 hour"
    echo "3. Every 2 hours"
    echo "4. Every 4 hours"
    echo "5. Every 6 hours"
    echo "6. Every 12 hours"
    echo "7. Every 24 hours"
    echo
    read -p "Enter your choice: " time_choice
    # Validate user input for restart time interval
    case $time_choice in
        1)
            restart_time="*/30 * * * *"
            ;;
        2)
            restart_time="0 * * * *"
            ;;
        3)
            restart_time="0 */2 * * *"
            ;;
        4)
            restart_time="0 */4 * * *"
            ;;
        5)
            restart_time="0 */6 * * *"
            ;;
        6)
            restart_time="0 */12 * * *"
            ;;
        7)
            restart_time="0 0 * * *"
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter a number between 1 and 7.${NC}\n"
            sleep 2
            return 1
            ;;
    esac


    # remove cronjob created by this script
    delete_cron_job > /dev/null 2>&1
    
    # Path to reset file
    local reset_path="/root/easytier/reset.sh"
    
    #add cron job to kill the running easymesh processes
    cat << EOF > "$reset_path"
#! /bin/bash
pids=\$(pgrep easytier)
sudo kill -9 \$pids
sudo systemctl daemon-reload
sudo systemctl restart $service_name
EOF

    # make it +x
    chmod +x "$reset_path"
    
    # Save existing crontab to a temporary file
    crontab -l > /tmp/crontab.tmp

    # Append the new cron job to the temporary file
    echo "$restart_time $reset_path #$service_name" >> /tmp/crontab.tmp

    # Install the modified crontab from the temporary file
    crontab /tmp/crontab.tmp

    # Remove the temporary file
    rm /tmp/crontab.tmp
    
    echo
    colorize green "Cron-job added successfully to restart the service '$service_name'." bold
    sleep 2
}

delete_cron_job() {
    echo
    local service_name="easymesh.service"
    local reset_path="/root/easytier/reset.sh"
    
    crontab -l | grep -v "#$service_name" | crontab -
    rm -f "$reset_path" >/dev/null 2>&1
    
    colorize green "Cron job for $service_name deleted successfully." bold
    
    sleep 2
}

set_cronjob(){
   	clear
   	colorize cyan "Cron-job setting menu" bold
   	echo 
   	
   	colorize green "1) Add a new cronjob"
   	colorize red "2) Delete existing cronjob"
   	colorize reset "3) Return..."
   	
   	echo
   	echo -ne "Select you option [1-3]: "
   	read -r choice
   	
   	case $choice in 
   		1) add_cron_job ;;
   		2) delete_cron_job ;;
   		3) return 0 ;;
   		*) colorize red "Invalid option!" && sleep 1 && return 1 ;;
   	esac
   	
}

check_core_status(){
    DEST_DIR="/root/easytier"
    FILE1="easytier-core"
    FILE2="easytier-cli"
    FILE3="easytier-web"
    FILE4="easytier-web-embed"
    
        if [ -f "$DEST_DIR/$FILE1" ] && [ -f "$DEST_DIR/$FILE2" ] && [ -f "$DEST_DIR/$FILE3" ] && [ -f "$DEST_DIR/$FILE4" ]; then
        colorize green "EasyMesh Core v2.4.3 Installed" bold
        return 0
    else
        colorize red "EasyMesh Core v2.4.3 not found" bold
        return 1
    fi
}

# New function to remove core
remove_easymesh_core(){
	echo
	
	if [[ ! -d '/root/easytier' ]]; then
		 colorize red "	EasyMesh directory not found." bold
		 sleep 2
		 return 1
	fi
	
	
	rm -rf /root/easytier &> /dev/null
	
	colorize green "	Easymesh core deleted successfully." bold
	sleep 2

}
# Function to display menu
display_menu() {
    clear
# Print the header with colors
echo -e "   ${CYAN}╔════════════════════════════════════════╗"
echo -e "   ║            🌐 ${WHITE}EasyMesh v2.4.3           ${CYAN}║"
echo -e "   ║        ${WHITE}VPN Network Solution            ${CYAN}║"
echo -e "   ╠════════════════════════════════════════╣"
echo -e "   ║  ${WHITE}Core Version: 2.4.3                    ${CYAN}║"
echo -e "   ║  ${WHITE}Telegram Channel: @Gozar_Xray         ${CYAN}║"
echo -e "   ║  ${WHITE}GitHub: github.com/mordak-95/hex-mesh  ${CYAN}║"
echo -e "   ╠════════════════════════════════════════╣${RESET}"
echo -e "   ║        $(check_core_status)         ║"
echo -e "   ╚════════════════════════════════════════╝"

    echo ''
    colorize green "	[1] Connect to the Mesh Network" bold 
    colorize yellow "	[2] Display Peers" 
    colorize cyan "	[3] Display Routes" 
    colorize reset "	[4] Peer-Center"
    colorize reset "	[5] Display Secret Key"
    colorize reset "	[6] Web Interface Info"
    colorize reset "	[7] Start/Stop Web Interface"
    colorize reset "	[8] View Service Status"  
    colorize reset "	[9] Debug Web Interface"
    colorize reset "	[10] Test Web Parameters"
    colorize reset "	[11] Set Watchdog [Auto-Restarter]"
    colorize reset "	[12] Cron-jon setting"   
    colorize yellow "	[13] Restart Service" 
    colorize red "	[14] Remove Service" 
    colorize magenta "	[15] Remove Core" 
    
    echo -e "	[0] Exit" 
    echo ''
}


# Function to read user input
read_option() {
	echo -e "\t-------------------------------"
    echo -en "\t${MAGENTA}\033[1mEnter your choice:${RESET} "
    read -p '' choice 
    case $choice in
        1) connect_network_pool ;;
        2) display_peers ;;
        3) display_routes ;;
        4) peer_center ;;
        5) show_network_secret ;;
        6) show_web_interface_info ;;
        7) manage_web_interface ;;
        8) view_service_status ;;
        9) debug_web_interface ;;
        10) test_web_embed_parameters ;;
        11) set_watchdog ;;
        12) set_cronjob ;;
        13) restart_easymesh_service ;;
        14) remove_easymesh_service ;;
        15) remove_easymesh_core ;;
        0) exit 0 ;;
        *) colorize red "	Invalid option!" bold && sleep 1 ;;
    esac
}

# Main script
while true
do
    display_menu
    read_option
done
