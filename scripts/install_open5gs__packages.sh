# --- OS Detection and Repository Setup ---
log_step "Detecting OS and Setting up Open5GS Repository"
OS_ID=""
OS_VERSION_ID=""
if [ -f /etc/os-release ]; then
    source /etc/os-release
    OS_ID="$ID"
    OS_VERSION_ID="$VERSION_ID"
else
    log_error "Could not determine OS type (/etc/os-release not found)"; exit 1;
fi
if [[ "$OS_ID" == "ubuntu" ]]; then
    OS_VERSION_MAJOR=$(echo "$OS_VERSION_ID" | cut -d'.' -f1)
    if [[ "$OS_VERSION_MAJOR" == "24" ]]; then
        log_info "Detected Ubuntu $OS_VERSION_ID LTS. Adding Open5GS PPA..."
        apt-get update -y >/dev/null 2>&1 || log_warn "apt update failed (continuing...)"
        apt-get install -y software-properties-common || { log_error "Failed to install software-properties-common"; exit 1; }
        add-apt-repository -y ppa:open5gs/latest || { log_error "Failed to add Open5GS PPA"; exit 1; }
    else
        log_error "Unsupported Ubuntu version: $OS_VERSION_ID. Only 24.04 LTS is supported by this script."
        exit 1
    fi
elif [[ "$OS_ID" == "debian" ]]; then
    if [[ "$OS_VERSION_ID" == "12" ]]; then
        log_info "Detected Debian $OS_VERSION_ID. Adding Open5GS repository..."
        apt-get update -y >/dev/null 2>&1 || log_warn "apt update failed (continuing...)"
        apt-get install -y wget gnupg curl || { log_error "Failed to install prerequisite packages (wget, gnupg, curl)"; exit 1; }
        mkdir -p /etc/apt/keyrings
        DEBIAN_VERSION_NUM="12"
        REPO_URL="https://download.opensuse.org/repositories/home:/acetcom:/open5gs:/latest/Debian_${DEBIAN_VERSION_NUM}/Release.key"
        REPO_LIST_ENTRY="deb [signed-by=/etc/apt/keyrings/open5gs.gpg] http://download.opensuse.org/repositories/home:/acetcom:/open5gs:/latest/Debian_${DEBIAN_VERSION_NUM}/ ./"
        log_info "Using repository for Debian $DEBIAN_VERSION_NUM"
        curl -fsSL "$REPO_URL" | gpg --dearmor -o /etc/apt/keyrings/open5gs.gpg
        if [ $? -ne 0 ]; then log_error "Failed to download or dearmor Open5GS GPG key from $REPO_URL"; exit 1; fi
        echo "$REPO_LIST_ENTRY" > /etc/apt/sources.list.d/open5gs.list
        if [ $? -ne 0 ]; then log_error "Failed to write Open5GS sources list"; exit 1; fi
    else
        log_error "Unsupported Debian version: $OS_VERSION_ID. Only Debian 12 is supported by this script."
        exit 1
    fi
else
    log_error "Unsupported OS: $OS_ID"; exit 1;
fi
log_info "Repository setup complete."

# --- Package Installation ---
log_step "Updating Package Lists"
apt-get update || { log_error "Failed to update package lists"; exit 1; }
log_info "Package lists updated."

log_step "Installing Open5GS Packages (Excluding WebUI)"
apt-get install -y open5gs-amf open5gs-ausf open5gs-hss open5gs-mme open5gs-nrf open5gs-nssf open5gs-pcf open5gs-smf open5gs-sgwc open5gs-sgwu open5gs-udr open5gs-upf open5gs-udm open5gs-pcrf || { log_error "Failed to install Open5GS component packages"; exit 1; }
dpkg -s open5gs-mme &> /dev/null || { log_error "open5gs-mme package not found after install attempt."; exit 1; }
dpkg -s open5gs-pcrf &> /dev/null || { log_error "open5gs-pcrf package not found after install attempt."; exit 1; }
log_info "Open5GS core packages (including PCRF) installed."

log_step "Installing Required Utilities (iptables, persistence tools)"
# Preseed iptables-persistent so it does not stop the install with an
# interactive "save current rules?" debconf dialog.
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get install -y iptables iptables-persistent yq || { log_error "Failed to install required utilities (iptables, iptables-persistent, yq)"; exit 1; }
if ! command -v iptables &> /dev/null; then log_error "iptables command not found after installation attempt."; exit 1; fi
if ! command -v yq &> /dev/null; then log_error "yq command not found after installation attempt."; exit 1; fi
log_info "Required base utilities are installed."