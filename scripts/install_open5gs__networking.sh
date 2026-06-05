#!/bin/bash

# --- Simple Network Configuration for Open5GS ---
log_step "Configuring Network Settings (Simple LTE WAN Default Route + NAT)"

# Detect distribution
DISTRO=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="$ID"
fi

log_info "Detected distribution: $DISTRO"

# --- Validate required variables ---
if [ -z "$UE_SUBNET" ]; then
    log_error "Required variable UE_SUBNET not set"
    exit 1
fi

# --- Set LTE WAN Interface ---
if [ -n "$USER_WAN_INTERFACE" ] && [ "$USER_WAN_INTERFACE" != "dynamic" ]; then
    LTE_WAN_INTERFACE="$USER_WAN_INTERFACE"
    log_info "Using LTE WAN interface from config: $LTE_WAN_INTERFACE"
else
    log_error "USER_WAN_INTERFACE not found in configuration or still set to 'dynamic'. Please run configure_installation.sh first."
    exit 1
fi

# Validate that the LTE WAN interface exists
if ! ip link show "$LTE_WAN_INTERFACE" &> /dev/null; then
    log_error "LTE WAN interface $LTE_WAN_INTERFACE not found!"
    log_info "Available interfaces:"
    ip link show | grep "^[0-9]" | awk '{print $2}' | sed 's/:$//'
    exit 1
fi

# --- Get LTE WAN Gateway ---
LTE_WAN_SUBNET=$(ip route show dev "$LTE_WAN_INTERFACE" | grep "proto kernel" | awk '{print $1}' | head -1)

# Prefer the gateway from an existing default route on this interface.
# Only fall back to guessing .1 if no default route exists yet.
LTE_WAN_GATEWAY=$(ip route show default | awk -v dev="$LTE_WAN_INTERFACE" '$0 ~ ("dev " dev) {for (i=1;i<NF;i++) if ($i=="via") {print $(i+1); exit}}')
if [ -z "$LTE_WAN_GATEWAY" ]; then
    LTE_WAN_GATEWAY="${LTE_WAN_SUBNET%.*}.1"
    log_warn "No existing default route on $LTE_WAN_INTERFACE; assuming gateway is $LTE_WAN_GATEWAY"
fi

log_info "LTE WAN subnet: $LTE_WAN_SUBNET, Gateway: $LTE_WAN_GATEWAY"

# Test if gateway is reachable
if ! ping -c 2 -W 3 "$LTE_WAN_GATEWAY" &> /dev/null; then
    log_error "Gateway $LTE_WAN_GATEWAY is not reachable!"
    exit 1
fi

log_info "Gateway $LTE_WAN_GATEWAY is reachable"

# --- Replace System Default Route ---
log_info "Replacing system default route with LTE WAN interface..."

# Remove existing default routes
log_info "Removing existing default routes..."
while ip route del default 2>/dev/null; do
    log_info "Removed a default route"
done

# Add new default route via LTE WAN
log_info "Adding default route via $LTE_WAN_GATEWAY on $LTE_WAN_INTERFACE"
if ip route add default via "$LTE_WAN_GATEWAY" dev "$LTE_WAN_INTERFACE"; then
    log_info "✓ System default route now uses $LTE_WAN_INTERFACE"
else
    log_error "Failed to add default route"
    exit 1
fi

# Test internet connectivity
if ping -c 2 -W 3 8.8.8.8 &> /dev/null; then
    log_info "✓ Internet connectivity confirmed through $LTE_WAN_INTERFACE"
else
    log_error "✗ Internet connectivity test failed"
    exit 1
fi

# --- Enable IP Forwarding ---
log_info "Enabling IP forwarding..."
SYSCTL_D_CONF="/etc/sysctl.d/99-open5gs-forward.conf"

echo "net.ipv4.ip_forward=1" > "$SYSCTL_D_CONF" || { 
    log_error "Failed to write sysctl config"; 
    exit 1; 
}

# Apply immediately
sysctl -w net.ipv4.ip_forward=1
log_info "IP forwarding enabled"

# --- Simple NAT Configuration ---
log_info "Configuring simple NAT for UE subnet $UE_SUBNET..."

# Backup existing iptables rules
BACKUP_FILE="/etc/iptables/rules.v4.backup.$(date +%Y%m%d_%H%M%S)"
mkdir -p /etc/iptables
if command -v iptables-save &> /dev/null; then
    iptables-save > "$BACKUP_FILE" 2>/dev/null && log_info "Backed up existing iptables rules"
fi

# Clear any existing Open5GS rules
iptables -t nat -D POSTROUTING -s "$UE_SUBNET" -j MASQUERADE 2>/dev/null || true
iptables -D FORWARD -s "$UE_SUBNET" -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -d "$UE_SUBNET" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true

# Add simple NAT rule
log_info "Adding MASQUERADE rule for UE subnet $UE_SUBNET"
if iptables -t nat -A POSTROUTING -s "$UE_SUBNET" -j MASQUERADE; then
    log_info "✓ NAT rule added"
else
    log_error "Failed to add NAT rule"
    exit 1
fi

# Add FORWARD rules
log_info "Adding FORWARD rules..."
iptables -A FORWARD -s "$UE_SUBNET" -j ACCEPT
iptables -A FORWARD -d "$UE_SUBNET" -m state --state RELATED,ESTABLISHED -j ACCEPT
log_info "✓ FORWARD rules added"

# --- Verification ---
log_info "Verifying configuration..."

# Check default route
if ip route show default | grep -q "$LTE_WAN_INTERFACE"; then
    log_info "✓ Default route uses $LTE_WAN_INTERFACE"
else
    log_error "✗ Default route verification failed"
    exit 1
fi

# Check NAT rule
if iptables -t nat -C POSTROUTING -s "$UE_SUBNET" -j MASQUERADE 2>/dev/null; then
    log_info "✓ NAT MASQUERADE rule verified"
else
    log_error "✗ NAT rule verification failed"
    exit 1
fi

# --- Save Configuration for Persistence ---
log_info "Saving configuration for persistence..."

# Save iptables rules
IPTABLES_RULES_FILE="/etc/iptables/rules.v4"
if iptables-save > "$IPTABLES_RULES_FILE"; then
    log_info "✓ Iptables rules saved to $IPTABLES_RULES_FILE"
else
    log_warn "Failed to save iptables rules"
fi

# Create simple startup script to restore routing
cat > /usr/local/bin/open5gs-restore-route.sh << EOF
#!/bin/bash
# Simple script to restore LTE WAN default route on boot

LTE_WAN_INTERFACE="$LTE_WAN_INTERFACE"
LTE_WAN_GATEWAY="$LTE_WAN_GATEWAY"

# Wait for interface
timeout=30
while [ \$timeout -gt 0 ]; do
    if ip link show "\$LTE_WAN_INTERFACE" &> /dev/null; then
        break
    fi
    sleep 1
    timeout=\$((timeout - 1))
done

if [ \$timeout -eq 0 ]; then
    echo "ERROR: LTE WAN interface \$LTE_WAN_INTERFACE not available"
    exit 1
fi

# Test gateway
if ping -c 1 -W 2 "\$LTE_WAN_GATEWAY" &> /dev/null; then
    # Remove any existing default routes and add LTE WAN route
    while ip route del default 2>/dev/null; do :; done
    ip route add default via "\$LTE_WAN_GATEWAY" dev "\$LTE_WAN_INTERFACE"
    echo "Restored default route via \$LTE_WAN_INTERFACE"
fi
EOF

chmod +x /usr/local/bin/open5gs-restore-route.sh

# Create systemd service for route restoration
cat > /etc/systemd/system/open5gs-route.service << 'EOF'
[Unit]
Description=Open5GS LTE WAN Default Route
After=network.target
Before=open5gs-upfd.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/open5gs-restore-route.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
if command -v systemctl &> /dev/null; then
    systemctl daemon-reload
    systemctl enable open5gs-route.service
    log_info "✓ Route restoration service enabled"
fi

log_info "Simple network configuration completed!"
log_info "System default route: $LTE_WAN_INTERFACE via $LTE_WAN_GATEWAY"
log_info "UE subnet $UE_SUBNET will be NATed through system default route" 
