```
  _____                    _       _   _____    _____    _____ 
 |  __ \                  (_)     | | | ____|  / ____|  / ____|
 | |__) |   __ _   _ __    _    __| | | |__   | |  __  | (___  
 |  _  /   / _\ | |  _ \  | |  / _\ | |___ \  | | |_ |  \___  \ 
 | | \ \  | (_| | | |_) | | | | (_| |  ___) | | |__| |  ____) |
 |_|  \_\  \__,_| | .__/  |_|  \__,_| |____/   \_____| |_____/ 
                  | |                                          
                  |_|                                          
```

# Rapid5GS

Deploy your mobile network core in minutes. Rapid5GS turns a stock Ubuntu 24.04 LTS or Debian 12 server into a production-ready [Open5GS](https://open5gs.org/) LTE/5G packet core (EPC/5GC). One command. Free and open source under GPL v3. Written by WISP operators who got tired of six-figure core quotes.

Website: [rapid5gs.com](https://rapid5gs.com/)

## Quick Start

Run this on a fresh Ubuntu 24.04 LTS or Debian 12 box:

```bash
git clone https://github.com/joshualambert/rapid5gs.git && cd rapid5gs && chmod +x install.sh && sudo ./install.sh
```

About twenty minutes later you have a running core and a web UI for subscriber management.

## System Requirements

- Ubuntu Server 24.04 LTS or Debian 12, freshly installed
- Root privileges (sudo)
- 4GB+ RAM
- 20GB+ free disk space
- Two distinct IPv4 addresses (two NICs, or a virtual interface)
- A CPU with AVX support (required by MongoDB 5.0+; most hardware from the last decade qualifies)

The installer's requirements check (option 1) verifies all of this for you.

> **IMPORTANT**: Rapid5GS is only tested against fresh installations of Ubuntu 24.04 LTS or Debian 12. Install it before any other packages or system modifications.

## What the Installer Does

`install.sh` walks you through a numbered menu:

1. **Check System Requirements**: OS version, RAM, disk, IPv4 addresses, CPU AVX support
2. **Configure Installation**: interfaces, PLMN (MCC/MNC/TAC), APN, DNS, WebUI credentials
3. **Install MongoDB**
4. **Install NodeJS**
5. **Install Open5GS**: packages, YAML configuration, networking and NAT rules, systemd services
6. **Install Open5GS Web UI**: subscriber management behind NGINX
7. **Health Check**: verify every service is up and configured correctly
8. **Reboot Services**

It deploys both the 4G EPC (MME, HSS, SGW-C/U, PCRF) and the 5G core functions (AMF, UPF, NRF, AUSF, UDM, UDR, NSSF, PCF, BSF), so the same box serves LTE today and 5G when you're ready. An uninstall script (`scripts/uninstall.sh`) and an SSL configuration script for the WebUI are included.

## Network Control Interface

After installation, monitor and control your network with:

```bash
chmod +x control.sh && sudo ./control.sh
```

The control panel gives you:

1. **EPC Throughput Monitor**: real-time traffic and performance
2. **eNB Status**: connected base stations at a glance
3. **UE Status**: connected user devices and their activity
4. **Live MME Logs**: real-time Mobility Management Entity tail
5. **Live SMF Logs**: real-time Session Management Function tail

No digging through config files or journalctl syntax to see what your network is doing.

## Current Limitations

- **NAT mode only**: subscriber traffic is NATed on the core itself. Routed IP pools and public customer IPs are a [Rapid5GS Pro](https://theedgemile.com/product/rapid5gs-pro/) feature.
- **Single instance**: designed for single-box deployment.

## Rapid5GS Pro

Running a real network? [Rapid5GS Pro](https://theedgemile.com/product/rapid5gs-pro/) is the commercial version, with development led by Michael Halls at [Nimbus Solutions](https://nimbussolutions.org). It adds:

- A full web GUI for core management
- A multi-UPF/SMF network optimization stack with Linux tuning
- Direct routing across multiple APNs, including public IPs to customer devices
- 8 hours of expert deployment support

$9,950 one-time, per core. No recurring license or per-subscriber fees. Purchasing Pro funds continued development of this open source version.

## Tested Hardware

Any standards-compliant eNodeB should work, but these units are tested on production Rapid5GS networks:

**Base stations (eNBs/gNBs)**

- Nokia AZQC CBRS (recommended)
- Baicells 436Q (recommended)
- Baicells 430i and Nova 233
- Airspan AirHarmony and AirSpeed

**User equipment (UEs/CPE)**

- Nokia FastMile 5G16-A and 5G16-B (recommended)
- Global Telecom Titan 4000
- BEC RidgeWave 6900
- Airspan AirSpot

Refurbished, tested CBRS hardware (Baicells 436Q units, Nokia AZQC RRHs, and complete 3-sector Nokia site kits with PCI planning, SAS setup, and core configuration) is sold at [The Edge Mile](https://theedgemile.com/). Hardware purchases fund Rapid5GS development.

## Deployment Help

- **Tower and sector installation**: CBRS gear must be installed and registered by a Certified Professional Installer (CPI) under FCC Part 96. [Vertical Axis](https://vertical-axis.com/services/sector-and-backhaul/) handles CBRS sector builds, SAS registration, antennas, and backhaul, and they know this stack.
- **Consulting**: I'm available for hire for network planning, construction, licensing, and deployment of Rapid5GS in your network. Contact me at [joshlambert.xyz/contact](https://joshlambert.xyz/contact/).
- **Marketing**: [ISP Hyperdrive](https://isphyperdrive.com/) builds subscriber-acquisition websites and runs marketing for WISPs and broadband operators.

## Acknowledgments

- The [Open5GS team](https://open5gs.org/), for building an excellent open source mobility core.
- David Peterson ([4GEngineer.com](https://4gengineer.com)) and Michael Halls ([nimbussolutions.org](https://nimbussolutions.org)), for teaching me the basics of LTE.
- Nick Jones ([omnitouch.co.au](https://omnitouch.co.au)), for helping me set up my first Open5GS core.
- Sarah Kerr ([isptechnology.ca](https://isptechnology.ca)) and Anthony Polsinelli ([carbonnetworksolutions.com](https://carbonnetworksolutions.com/)), for lots of patience with the MikroTik layer.
- John Nettles and [Pine Belt Communications](https://www.pinebelt.net/), for mobility expertise and Band 71 spectrum during development.

## Sponsored By

- [Centreville Tech, LLC](https://centrevilletech.com)
- [Alabama Lightwave, Inc.](https://alabamalightwave.com)

## License

GPL v3. See [LICENSE](LICENSE). Provided as-is, without warranty of any kind; see the [website terms](https://rapid5gs.com/terms/) for details.
