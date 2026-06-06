#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check for root privileges
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Check if NodeJS is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}NodeJS is not installed. Please install NodeJS first using the menu option.${NC}"
    exit 1
fi

# Check if configuration file exists
if [ ! -f "/etc/open5gs/install.conf" ]; then
    echo -e "${RED}Installation configuration file not found. Please run the Configure Installation option first.${NC}"
    exit 1
fi

# Install Open5GS WebUI with default settings
echo -e "${GREEN}Installing Open5GS WebUI...${NC}"
curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -
echo -e "${GREEN}Open5GS WebUI installed successfully!${NC}"

# Install Nginx for reverse proxy
echo -e "${GREEN}Installing and configuring Nginx as reverse proxy...${NC}"
apt update && apt install -y nginx

# Extract the management IP from the configuration file and remove CIDR notation
MGMT_IP_WITH_CIDR=$(grep '^MGMT_IP=' /etc/open5gs/install.conf | cut -d '=' -f2)
MGMT_IP=$(echo $MGMT_IP_WITH_CIDR | cut -d '/' -f1)
echo -e "${GREEN}Using management IP: ${MGMT_IP}${NC}"

# Configure Nginx for the web UI with the management IP
cat <<EOL > /etc/nginx/sites-available/webui
server {
    listen 80;
    server_name $MGMT_IP;

    location / {
        proxy_pass http://127.0.0.1:9999;  # WebUI listens on IPv4 loopback port 9999
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Remove default configuration if it exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
fi

# Enable the Nginx configuration
ln -sf /etc/nginx/sites-available/webui /etc/nginx/sites-enabled/
nginx -t  # Test the configuration
systemctl restart nginx

echo -e "${GREEN}Open5GS WebUI is now accessible at http://${MGMT_IP}${NC}"