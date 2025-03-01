#!/bin/bash
# Ultimate Info Script
# Dump most essential info about system & platform into a file

# Get the actual user, ignoring 'root' if using sudo
REAL_USER=$(logname 2>/dev/null || echo $SUDO_USER || echo $USER)

# Timestamped log file
LOGFILE="ultinfo-$(date '+%Y%m%d-%H%M%S').log"

# Start logging
{
    echo "### SYSTEM INFO LOG ###"
    echo "Generated on: $(date)"
    echo "Executed by: $REAL_USER @ $(hostname)"
    echo "--------------------------------------"
    
    # OS Info
    echo -e "\n### OS INFO ###"
    cat /etc/os-release 2>/dev/null
    
    # Kernel & Uptime
    echo -e "\n### KERNEL & UPTIME ###"
    uname -a
    uptime
    
    # CPU Info
    echo -e "\n### CPU INFO ###"
    lscpu
    
    # Memory Info
    echo -e "\n### MEMORY INFO ###"
    free -h
    
    # Disk & Filesystem Info
    echo -e "\n### DISK & FILESYSTEM INFO ###"
    lsblk
    echo -e "\n### Mounted Filesystems & FSTAB ###"
    cat /etc/fstab 2>/dev/null
    mount
    
    # Installed Packages (Auto-detect package manager)
    echo -e "\n### INSTALLED PACKAGES ###"
    if command -v pacman &>/dev/null; then
        sudo -u "$REAL_USER" pacman -Q
    elif command -v dpkg &>/dev/null; then
        dpkg -l
    elif command -v rpm &>/dev/null; then
        rpm -qa
    elif command -v apk &>/dev/null; then
        apk list --installed
    else
        echo "Package manager not recognized."
    fi
    
    # System Services
    echo -e "\n### SYSTEM SERVICES ###"
    systemctl list-units --type=service --all 2>/dev/null
    
    # Network Information (No private IPs)
    echo -e "\n### NETWORK INFO (SANITIZED) ###"
    ip -o addr show | awk '{print $2, $3, $4}' | grep -v '127.0.0.1'
    echo -e "\n### Active Connections ###"
    ss -tulnp 2>/dev/null
    
    # Hardware Info
    echo -e "\n### HARDWARE INFO ###"
    lspci
    lsusb
    
    # Users and Groups
    echo -e "\n### USERS & GROUPS ###"
    echo "Logged-in users:"
    w
    echo -e "\nSystem Users (non-service accounts filtered):"
    awk -F: '$3 >= 1000 {print $1}' /etc/passwd
    echo -e "\nSystem Groups:"
    cut -d: -f1 /etc/group
    
    # Running Processes
    echo -e "\n### RUNNING PROCESSES ###"
    ps aux --sort=-%mem | head -n 20  # Top 20 processes by memory usage
    
    # Logs (Sanitized)
    echo -e "\n### KERNEL LOGS (Last 50 lines) ###"
    dmesg | tail -n 50

    echo -e "\n### LAST 10 LOGINS ###"
    last -n 10

    # Firewall Rules (Minimal Output)
    echo -e "\n### FIREWALL RULES ###"
    if command -v iptables &>/dev/null; then
        iptables -L --line-numbers -n | head -n 20
    elif command -v nft &>/dev/null; then
        nft list ruleset | head -n 20
    else
        echo "No firewall rules detected."
    fi
    
} > "$LOGFILE"

# Open log with 'more'
sudo -u "$REAL_USER" more "$LOGFILE"
