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

# Function to check network interfaces
check_network_interfaces() {
    echo -e "\n${YELLOW}Checking network interfaces...${NC}"
    
    # Get physical interfaces
    local physical_interfaces=$(ip -br link show | grep -v lo | grep -v '@' | awk '{print $1}')
    local physical_count=$(echo "$physical_interfaces" | wc -l)
    
    # Get all IPv4 addresses (including virtual)
    local ip_addresses=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}')
    local ip_count=$(echo "$ip_addresses" | wc -l)
    
    echo -e "${YELLOW}Physical interfaces:${NC}"
    echo "$physical_interfaces"
    echo -e "\n${YELLOW}Available IPv4 addresses:${NC}"
    echo "$ip_addresses"
    
    if [ "$ip_count" -ge 2 ]; then
        echo -e "${GREEN}✓ Found $ip_count IPv4 addresses (minimum 2 required)${NC}"
        return 0
    else
        echo -e "${RED}✗ Insufficient IPv4 addresses. Open5GS requires at least 2 distinct IPv4 addresses.${NC}"
        echo -e "${YELLOW}You can add virtual interfaces using:${NC}"
        echo -e "sudo ip addr add <IP>/24 dev <interface>:1"
        return 1
    fi
}

# Function to check storage
check_storage() {
    echo -e "\n${YELLOW}Checking storage...${NC}"
    local available_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -ge 20 ]; then
        echo -e "${GREEN}✓ Sufficient storage available: ${available_space}GB${NC}"
        return 0
    else
        echo -e "${RED}✗ Insufficient storage. Open5GS requires at least 20GB of free space.${NC}"
        return 1
    fi
}

# Function to check RAM
check_ram() {
    echo -e "\n${YELLOW}Checking RAM...${NC}"
    local total_ram=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -ge 4 ]; then
        echo -e "${GREEN}✓ Sufficient RAM available: ${total_ram}GB${NC}"
        return 0
    else
        echo -e "${RED}✗ Insufficient RAM. Open5GS requires at least 4GB of RAM.${NC}"
        return 1
    fi
}

# Function to check CPU AVX support (required by MongoDB 5.0+)
check_cpu_avx() {
    echo -e "\n${YELLOW}Checking CPU instruction set...${NC}"
    if grep -q -m1 -w avx /proc/cpuinfo; then
        echo -e "${GREEN}\u2713 CPU supports AVX${NC}"
        return 0
    else
        echo -e "${RED}\u2717 CPU does not support AVX.${NC}"
        echo "MongoDB 5.0 and newer requires a CPU with AVX instructions."
        echo "Without AVX, mongod crashes on startup (invalid opcode) and the"
        echo "HSS, PCRF, and WebUI cannot run."
        echo "Use AVX-capable hardware (Intel Sandy Bridge / AMD Bulldozer or"
        echo "newer). On a VM, also make sure the hypervisor passes AVX through"
        echo "to the guest (e.g. CPU type 'host' on Proxmox, not kvm64)."
        return 1
    fi
}

# Function to check Ubuntu version
check_os_version() {
    echo -e "\n${YELLOW}Checking operating system...${NC}"
    if [ -f /etc/os-release ]; then
        # Get OS name and version from os-release file
        source /etc/os-release
        local os_name="$ID"
        local version="$VERSION_ID"
        
        if [[ "$os_name" == "ubuntu" && "$version" == "24.04"* ]]; then
            echo -e "${GREEN}✓ Compatible Ubuntu version: $version${NC}"
            return 0
        elif [[ "$os_name" == "debian" && "$version" == "12"* ]]; then
            echo -e "${GREEN}✓ Compatible Debian version: $version${NC}"
            return 0
        else
            echo -e "${RED}✗ Incompatible OS: $os_name $version${NC}"
            echo "This script is designed for Ubuntu 24.04 or Debian 12"
            return 1
        fi
    else
        echo -e "${RED}✗ Could not determine operating system version${NC}"
        return 1
    fi
}

# Run all checks
check_network_interfaces
network_check=$?
check_storage
storage_check=$?
check_ram
ram_check=$?
check_cpu_avx
avx_check=$?
check_os_version
os_check=$?

# Summary
echo -e "\n${GREEN}=== System Requirements Summary ===${NC}"
if [ "$network_check" -eq 0 ] && [ "$storage_check" -eq 0 ] && [ "$ram_check" -eq 0 ] && [ "$avx_check" -eq 0 ] && [ "$os_check" -eq 0 ]; then
    echo -e "${GREEN}✓ All system requirements met!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some system requirements are not met. Please address the issues above.${NC}"
    exit 1
fi 