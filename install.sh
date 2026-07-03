#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

clear

cat << "EOF"

  _____                    _       _   _____    _____    _____ 
 |  __ \                  (_)     | | | ____|  / ____|  / ____|
 | |__) |   __ _   _ __    _    __| | | |__   | |  __  | (___  
 |  _  /   / _\`| | '_ \  | |  / _\`| |___ \  | | |_ |  \___  \ 
 | | \ \  | (_| | | |_) | | | | (_| |  ___) | | |__| |  ____) |
 |_|  \_\  \__,_| | .__/  |_|  \__,_| |____/   \_____| |_____/ 
                  | |                                          
                  |_|                                          

EOF

# Main menu
while true; do
    echo -e "\n${GREEN}=== Rapid5GS Installation Menu ===${NC}"
    echo ""
    echo "1. 🔍 Check System Requirements"
    echo "2. ⚙️  Configure Installation"
    echo "3. 🗄️  Install MongoDB"
    echo "4. 💻 Install NodeJS"
    echo "5. 📡 Install Open5GS"
    echo "6. 🌐 Install Open5GS Web UI"
    echo "7. 🏥 Health Check"
    echo "8. 🔄 Reboot Services"
    echo "9. 👋 Exit"
    echo ""
    echo -e "${YELLOW}Note: Rapid5GS Pro is here! Web GUI, routed public IPs, multi-UPF optimization, and support: https://theedgemile.com/product/rapid5gs-pro/${NC}"
    echo -e "${YELLOW}Note: Tested, refurbished CBRS hardware for sale funds Rapid5GS development: https://theedgemile.com/${NC}"
    echo ""
    read -p "Enter an option (1-9) and press enter: " choice

    case $choice in
        1)
            echo -e "\n${YELLOW}Checking system requirements...${NC}"
            sudo bash scripts/check_requirements.sh
            ;;
        2)
            echo -e "\n${YELLOW}Running installation configuration...${NC}"
            sudo bash scripts/configure_installation.sh
            ;;
        3)
            echo -e "\n${YELLOW}Installing MongoDB...${NC}"
            sudo bash scripts/install_mongodb.sh
            ;;
        4)
            echo -e "\n${YELLOW}Installing NodeJS...${NC}"
            sudo bash scripts/install_nodejs.sh
            ;;
        5)
            echo -e "\n${YELLOW}Installing Open5GS...${NC}"
            sudo bash scripts/install_open5gs.sh
            ;;
        6)
            echo -e "\n${YELLOW}Installing Open5GS Web UI...${NC}"
            sudo bash scripts/install_webui.sh
            ;;
        7)
            echo -e "\n${YELLOW}Running health check...${NC}"
            sudo bash scripts/health_check.sh
            ;;
        8)
            echo -e "\n${YELLOW}Rebooting Open5GS services...${NC}"
            sudo bash scripts/reboot_services.sh
            ;;
        9)
            echo -e "\n${GREEN}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please select 1-9.${NC}"
            ;;
    esac
done
