#!/bin/bash
# Entropy Setup Manager Installer
# setup.sh - Checks dependencies and deploys project to /bin/setup-manager/

# Required dependencies
DEPS=(git dialog jq tree)

# Detect OS using /etc/os-release
OS_NAME=""
PKG_MGR=""
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_NAME=$ID
else
  echo "Cannot detect OS! Install dependencies manually."
  exit 1
fi

# Set package manager based on detected OS
case "$OS_NAME" in
  arch) PKG_MGR="sudo pacman -Sy --noconfirm" ;;
  debian|ubuntu) PKG_MGR="sudo apt install -y" ;;
  fedora) PKG_MGR="sudo dnf install -y" ;;
  opensuse*) PKG_MGR="sudo zypper install -y" ;;
  *) echo "Unsupported OS: $OS_NAME. Install ${DEPS[*]} manually."; exit 1 ;;
esac

# Install dependencies if missing
echo "Checking dependencies..."
for pkg in "${DEPS[@]}"; do
  command -v $pkg &>/dev/null || { echo "Installing: $pkg..."; $PKG_MGR $pkg; }
done

# Define variables
REPO="https://github.com/Entropy-Linux/Entropy-Setup-Manager"
INSTALL_DIR="/bin/setup-manager"
LINK="/bin/esm"

# Check if ESM is installed
if [[ -f "$INSTALL_DIR/esm.sh" ]]; then
  STATUS="ESM Installed"
else
  STATUS="ESM Not Found"
fi

# Menu function
menu() {
  local options=("Install / Reinstall ESM" "Update data (scripts)" "Remove ESM" "Exit")
  local selected=0
  while true; do
    clear
    echo "==============================="
    echo "   ESM Installer [setup.sh]   "
    echo ""
    echo "   [STATUS: $STATUS]   "
    echo ""

    for i in "${!options[@]}"; do
      if [[ $i -eq $selected ]]; then
        echo -e " > \e[1;32m${options[$i]}\e[0m"
      else
        echo "   ${options[$i]}"
      fi
    done

    read -rsn1 key
    case "$key" in
      $'\x1b') read -rsn2 -t 0.1 key
        case "$key" in
          '[A') ((selected=(selected-1+${#options[@]})%${#options[@]})) ;;  # Up arrow
          '[B') ((selected=(selected+1)%${#options[@]})) ;;  # Down arrow
        esac ;;
      "") return $selected ;;  # Enter key
    esac
  done
}

# Install/Reinstall function (overwrite only)
install_esm() {
  echo "Downloading ESM..."
  git clone --depth 1 "$REPO" /tmp/esm_install || { echo "Clone failed!"; exit 1; }

  echo "Installing to $INSTALL_DIR..."
  chmod +x /tmp/esm_install/esm.sh
  sudo mkdir -p "$INSTALL_DIR"
  sudo cp -a /tmp/esm_install/* "$INSTALL_DIR"

  echo "Creating symlink: $LINK -> $INSTALL_DIR/esm.sh"
  sudo ln -sf "$INSTALL_DIR/esm.sh" "$LINK"

  rm -rf /tmp/esm_install
  echo "Installation complete! Run 'esm' to start."
}

# Update only data (scripts)
update_data() {
  [[ ! -d "$INSTALL_DIR" ]] && { echo "ESM not installed!"; exit 1; }
  echo "Updating scripts & configs..."
  git clone --depth 1 "$REPO" /tmp/esm_update
  sudo cp -a /tmp/esm_update/data/* "$INSTALL_DIR/data/"
  rm -rf /tmp/esm_update
  echo "Update complete!"
}

# Remove ESM
remove_esm() {
  [[ ! -d "$INSTALL_DIR" ]] && { echo "ESM not installed!"; exit 1; }
  echo "Removing ESM..."
  sudo rm -rf "$INSTALL_DIR"
  sudo rm -f "$LINK"
  echo "ESM removed!"
}

# Main loop
while true; do
  menu
  choice=$?
  case $choice in
    0) install_esm ;;
    1) update_data ;;
    2) remove_esm ;;
    3) exit 0 ;;
  esac
  read -p "Press Enter to return to menu..."
done
