#!/bin/bash

# ╔══════════════════════════════════════════════╗
# ║            🪙 PlumMiner Installer             ║
# ║               Version: 1.0.0                 ║
# ╚══════════════════════════════════════════════╝

set -e

INSTALL_DIR="mining"
CONFIG_FILE="$INSTALL_DIR/config.json"
VERSION_FILE_URL="https://raw.githubusercontent.com/nayeembiminer/mining/main/VERSION"
REPO_URL="https://github.com/nayeembiminer/mining.git"
SCRIPT_VERSION="1.0.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ═══════════════════════════════════════════════
echo -e "${BLUE}🔧 Checking for updates...${NC}"
LATEST_VERSION=$(curl -s "$VERSION_FILE_URL")
if [[ "$LATEST_VERSION" != "$SCRIPT_VERSION" ]]; then
  echo -e "${YELLOW}⚠️  New version available: $LATEST_VERSION. Please update from the GitHub repo.${NC}"
fi

# ═══════════════════════════════════════════════
echo -e "${BLUE}📦 Cloning or updating PlumMiner repo...${NC}"
rm -rf "$INSTALL_DIR"
git clone "$REPO_URL" "$INSTALL_DIR"

# ═══════════════════════════════════════════════
echo -e "${BLUE}🔍 Detecting GPU devices...${NC}"
GPU_FOUND=false

if ! command -v lspci >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠️ 'lspci' not found. Attempting to install...${NC}"
  if [[ -f /etc/debian_version ]]; then
    sudo apt update && sudo apt install -y pciutils
  elif [[ -f /etc/redhat-release ]]; then
    sudo yum install -y pciutils
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm pciutils
  else
    echo -e "${RED}❌ Could not detect package manager. Please install 'pciutils' manually.${NC}"
  fi
fi

if command -v lspci >/dev/null 2>&1; then
  if lspci | grep -i 'nvidia\|amd\|ati'; then
    GPU_FOUND=true
  fi
fi

cpu_enabled=true
opencl_enabled=false
cuda_enabled=false

if [[ "$GPU_FOUND" == true ]]; then
  echo -e "${GREEN}✅ GPU detected on your system.${NC}"
  read -p "Do you want to mine using GPU? [y/N]: " gpu_choice
  if [[ "$gpu_choice" =~ ^[Yy]$ ]]; then
    cpu_enabled=false
    read -p "Enable OpenCL (AMD)? [y/N]: " opencl_choice
    read -p "Enable CUDA (NVIDIA)? [y/N]: " cuda_choice
    [[ "$opencl_choice" =~ ^[Yy]$ ]] && opencl_enabled=true
    [[ "$cuda_choice" =~ ^[Yy]$ ]] && cuda_enabled=true
  else
    echo -e "${GREEN}✅ Proceeding with CPU mining.${NC}"
  fi
else
  echo -e "${YELLOW}⚠️ No supported GPU detected. Defaulting to CPU mining.${NC}"
fi

# ═══════════════════════════════════════════════
echo -e "${BLUE}🔍 Checking configuration...${NC}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}⚠️  No config.json found. Generating a new one...${NC}"

    read -p "Enter your coin (e.g., DOGE): " new_coin
    read -p "Enter your wallet address: " new_wallet
    read -p "Enter your rig ID (default: plumrig): " new_rig
    read -p "Enter pool URL (default: rx.unmineable.com:3333): " new_url

    new_rig=${new_rig:-plumrig}
    new_url=${new_url:-rx.unmineable.com:3333}
    new_user="$new_coin:$new_wallet.$new_rig"

    cat > "$CONFIG_FILE" <<EOF
{
  "autosave": true,
  "background": false,
  "colors": true,
  "donate-level": 1,
  "log-file": null,
  "print-time": 60,
  "retries": 5,
  "retry-pause": 5,
  "syslog": false,
  "cpu": {
    "enabled": $cpu_enabled,
    "max-threads-hint": 100,
    "huge-pages": true,
    "hw-aes": null,
    "priority": null,
    "memory-pool": true,
    "yield": true,
    "force-argon2": false,
    "rx": [-1, -1, -1, -1]
  },
  "opencl": {
    "enabled": $opencl_enabled,
    "cache": true,
    "loader": null,
    "platform": null,
    "devices": [],
    "temps": false,
    "sync-dc-multiplex": false
  },
  "cuda": {
    "enabled": $cuda_enabled,
    "loader": null,
    "devices": [],
    "bfactor": 0,
    "bsleep": 0,
    "temps": false
  },
  "pools": [
    {
      "algo": "rx/0",
      "url": "$new_url",
      "user": "$new_user",
      "pass": "x",
      "rig-id": null,
      "nicehash": false,
      "keepalive": true,
      "enabled": true,
      "tls": false,
      "tls-fingerprint": null,
      "daemon": false,
      "socks5": null,
      "self-select": null
    }
  ],
  "api": {
    "id": null,
    "worker-id": null,
    "host": "127.0.0.1",
    "port": 0,
    "access-token": null,
    "ipv6": false,
    "restricted": true
  }
}
EOF

    echo -e "${GREEN}✅ config.json created successfully!${NC}\n"
fi
