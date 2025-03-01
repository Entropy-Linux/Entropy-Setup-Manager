#!/bin/bash

clear
echo " Simple Network Setup for Arch "

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "[!] This script needs to be run as root!"
    exit 1
fi

# Function to display network interfaces and configurations
display_interfaces() {
    echo -e "\n[+] Available Network Interfaces:"
    ip link show | awk -F ': ' '/^[0-9]+: / {print "  -> "$2}'

    echo -e "\n[+] Interface Details:"
    for iface in $(ls /sys/class/net/); do
        echo -e "\n[*] Interface: $iface"
        echo "  - MAC Address: $(cat /sys/class/net/$iface/address)"
        echo "  - Status: $(cat /sys/class/net/$iface/operstate)"
        ip -4 addr show "$iface" | grep -oP 'inet \K\S+'
        ip -6 addr show "$iface" | grep -oP 'inet6 \K\S+'
    done
}

# Function to display active connections and routes
display_network_status() {
    echo -e "\n[+] Default Gateway:"
    ip route show default

    echo -e "\n[+] Active Connections (Listening Ports):"
    ss -tulnp | grep -E 'LISTEN|ESTABLISHED'

    echo -e "\n[+] DNS Resolvers (/etc/resolv.conf):"
    cat /etc/resolv.conf

    echo -e "\n[+] ARP Table:"
    ip neigh show
}

# Function to display and diagnose network state
display_info() {
    echo -e "\n[+] Checking Network..."
    echo -e "\n[+] Pinging 8.8.8.8 & google.com..."
    if ping -c 3 8.8.8.8 && ping -c 3 google.com; then
        echo "[+] Internet connection is active."
    else
        echo "[-] Ping failed! Network might be down."
    fi
    
    echo -e "\n[+] Public IP Address:"
    curl -s ifconfig.me || curl -s ipinfo.io/ip && echo
    
    echo -e "\n[+] NetworkManager Status:"
    systemctl is-active NetworkManager && systemctl status NetworkManager --no-pager | head -n 10
}

# Step 1: Display network interfaces
display_interfaces

# Step 2: Show active network connections and status
display_network_status

# Step 3: Display initial network information
display_info

# Step 4: Check and fix /etc/resolv.conf
if ! grep -q "nameserver" /etc/resolv.conf; then
    echo "[-] No valid nameserver found in /etc/resolv.conf, adding Cloudflare DNS..."
    echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" | tee /etc/resolv.conf
else
    echo "[+] /etc/resolv.conf contains valid nameservers."
fi

# Step 5: Check if NetworkManager is installed and install if missing
if ! command -v NetworkManager &> /dev/null; then
    echo "[-] NetworkManager not found! Installing..."
    if pacman -Syu --noconfirm networkmanager; then
        echo "[+] NetworkManager installed successfully."
    else
        echo "[!] Failed to install NetworkManager!"
    fi
else
    echo "[+] NetworkManager is installed."
fi

# Step 6: Ensure NetworkManager is running
if ! systemctl is-active --quiet NetworkManager; then
    echo "[-] Starting NetworkManager..."
    systemctl start NetworkManager && systemctl enable NetworkManager
    echo "[+] NetworkManager started and enabled."
else
    echo "[+] NetworkManager is already running."
fi

# Step 7: Final network check after fixes
echo -e "\n[+] Rechecking network status..."
if ping -c 3 8.8.8.8; then
    echo "[+] Internet connection restored."
else
    echo "[-] Network still down. Do you want to manually connect to Wi-Fi? (y/n)"
    read -r choice
    if [[ "$choice" == "y" ]]; then
        echo "[+] Launching iwctl..."
        iwctl
    else
        echo "[!] Exiting. Please check your network manually."
    fi
fi
