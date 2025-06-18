#!/bin/bash

CONFIG_FILE="mining/config.json"
LOG_FILE="mining/plumminer.log"

# Colors
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

function show_banner() {
  clear
  echo -e "${CYAN}"
  echo "╔══════════════════════════════════════════════╗"
  echo "║         🪙 PlumMiner Installer               ║"
  echo "║               Version: 1.1.0                ║"
  echo "╚══════════════════════════════════════════════╝"
  echo -e "${NC}"
}

function show_current_config() {
  echo -e "${YELLOW}📄 Current config.json settings:${NC}"
  coin=$(jq -r '.pools[0].user' "$CONFIG_FILE" | cut -d ':' -f1)
  wallet=$(jq -r '.pools[0].user' "$CONFIG_FILE" | cut -d ':' -f2 | cut -d '.' -f1)
  worker=$(jq -r '.pools[0].user' "$CONFIG_FILE" | cut -d '.' -f2)
  url=$(jq -r '.pools[0].url' "$CONFIG_FILE")
  huge_pages=$(jq -r '.cpu."huge-pages"' "$CONFIG_FILE")
  gb_pages=$(jq -r '.randomx."1gb-pages"' "$CONFIG_FILE")

  echo -e "🔸 Coin: ${CYAN}${coin}${NC}"
  echo -e "🔸 Wallet: ${CYAN}${wallet}${NC}"
  echo -e "🔸 Worker: ${CYAN}${worker}${NC}"
  echo -e "🔸 Pool URL: ${CYAN}${url}${NC}"
  echo -e "🔸 Huge Pages: ${CYAN}${huge_pages}${NC}"
  echo -e "🔸 1GB Huge Pages: ${CYAN}${gb_pages}${NC}"
}

function change_config() {
  echo -e "${YELLOW}⚙️  Updating config.json...${NC}"
  read -p "Enter new coin (or press Enter to keep current): " new_coin
  read -p "Enter new wallet address (or press Enter to keep current): " new_wallet
  read -p "Enter new worker name (or press Enter to keep current): " new_worker
  read -p "Enter new pool URL (or press Enter to keep current): " new_url

  # Read current values
  current_user=$(jq -r '.pools[0].user' "$CONFIG_FILE")
  current_url=$(jq -r '.pools[0].url' "$CONFIG_FILE")

  # Decompose user
  current_coin=$(echo "$current_user" | cut -d ':' -f1)
  current_wallet=$(echo "$current_user" | cut -d ':' -f2 | cut -d '.' -f1)
  current_worker=$(echo "$current_user" | cut -d '.' -f2)

  coin=${new_coin:-$current_coin}
  wallet=${new_wallet:-$current_wallet}
  worker=${new_worker:-$current_worker}
  url=${new_url:-$current_url}

  new_user="${coin}:${wallet}.${worker}"

  # Apply changes using jq
  jq \
    --arg url "$url" \
    --arg user "$new_user" \
    '.pools[0].url = $url | .pools[0].user = $user' \
    "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

  echo -e "${GREEN}✅ config.json updated successfully.${NC}"
}

function ask_run_xmrig() {
  echo
  read -p "🚀 Do you want to run PlumMiner now? (y/n): " run_now
  if [[ "$run_now" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}⛏️  Starting PlumMiner...${NC}"
    cd mining && ./xmrig
  else
    echo -e "${CYAN}📌 You can run it anytime with:${NC} ${YELLOW}cd mining && ./xmrig${NC}"
  fi
}

# ==============================
# 🌟 START
# ==============================

show_banner

# 1st time install
if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "${YELLOW}🔧 Installing PlumMiner...${NC}"
  git clone https://github.com/nayeembiminer/mining.git
  cd mining || exit
  rm -f config.json

  read -p "Enter coin (e.g., SHIB): " coin
  read -p "Enter wallet address: " wallet
  read -p "Enter worker name [default: plum-worker]: " worker
  worker=${worker:-plum-worker}
  user="${coin}:${wallet}.${worker}"
  url="rx.unmineable.com:3333"

  echo -e "${YELLOW}⚙️  Generating config.json...${NC}"
  cat > config.json <<EOF
{
  "autosave": true,
  "cpu": {
    "enabled": true,
    "huge-pages": true
  },
  "randomx": {
    "1gb-pages": false
  },
  "pools": [
    {
      "url": "$url",
      "user": "$user",
      "pass": "x"
    }
  ]
}
EOF

  chmod +x xmrig
  echo -e "${GREEN}✅ Setup complete.${NC}"
  cd ..
else
  # Already installed
  echo -e "${GREEN}✅ Existing installation found.${NC}"
  show_current_config
  echo
  read -p "📝 Do you want to change config? (y/n): " change
  if [[ "$change" =~ ^[Yy]$ ]]; then
    change_config
  fi
fi

ask_run_xmrig
