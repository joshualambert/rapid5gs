#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Source the logo
source scripts/logo.sh

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

function draw_menu() {
    clear
    draw_logo
    echo -e "\n${GREEN}=== Rapid5GS Control Panel ===${NC}"
    echo ""
    echo "1. 📊 View EPC Throughput"
    echo "2. 📶 View eNB Status"
    echo "3. 📱 View UE Status"
    echo "4. 📝 Live Tail MME (Mobile Management Entity)"
    echo "5. 📝 Live Tail SMF (Session Management Function)"
    echo "6. 👋 Exit"
    echo ""
    echo -e "${YELLOW}Note: Rapid5GS Pro is here! Web GUI, routed public IPs, multi-UPF optimization, and support: https://theedgemile.com/product/rapid5gs-pro/${NC}"
    echo -e "${YELLOW}Note: Tested, refurbished CBRS hardware for sale funds Rapid5GS development: https://theedgemile.com/${NC}"
    echo ""
}

# Initial draw
draw_menu

# Main menu
while true; do
    read -p "Enter an option (1-6) and press enter: " choice

    case $choice in
        1)
            sudo bash scripts/speedometer.sh
            draw_menu
            ;;
        2)
            sudo bash scripts/monitor_enbs.sh
            draw_menu
            ;;
        3)
            sudo bash scripts/monitor_ues.sh
            draw_menu
            ;;
        4)
            sudo journalctl -u open5gs-mmed -f
            draw_menu
            ;;
        5)
            sudo journalctl -u open5gs-smfd -f
            draw_menu
            ;;
        6)
            echo -e "\n${GREEN}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please select 1-6.${NC}"
            ;;
    esac
done 
