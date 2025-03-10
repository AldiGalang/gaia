#!/bin/bash

# Warna teks
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_menu() {
    clear
    echo -e "${CYAN}==============================================${NC}"
    echo -e "  🚀 ${YELLOW}GaiaNet Node Management Script${NC} 🚀"
    echo -e "${CYAN}==============================================${NC}"
    echo -e "  ${GREEN}1.${NC} 📥 Install Node"
    echo -e "  ${GREEN}2.${NC} ℹ️  Show Node Information"
    echo -e "  ${GREEN}3.${NC} ❌ Exit"
    echo -e "${CYAN}==============================================${NC}"
}

install_multiple_nodes() {
    read -p "How many nodes do you want to install?: " node_count

    if ! [[ "$node_count" =~ ^[1-9][0-9]*$ ]]; then
        echo -e "${RED}❌ Input should be a positive number, example: 1${NC}"
        return 1
    fi

    sudo apt update && sudo apt upgrade -y
    sudo apt-get update && sudo apt-get upgrade -y

    for ((i=1; i<=node_count; i++)); do
        node_name=$(printf "gaia-%02d" $i)
        node_path="$HOME/$node_name"
        port=$((8000 + i - 1))             

        if [[ -d "$node_path" ]]; then
            echo -e "⚠️  ${YELLOW}Node $node_name already exists, skipping...${NC}"
            continue
        fi

        echo -e "🚀 ${GREEN}Installing node: $node_name...${NC}"
        mkdir -p "$node_path"
        curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash -s -- --base "$node_path"
        source $HOME/.bashrc
        gaianet init --base "$node_path" --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json
        gaianet config --base "$node_path" --port "$port"
        gaianet init --base "$node_path"
    done

    echo -e "🛑 ${YELLOW}Stopping any existing GaiaNet processes on ports...${NC}"
    for ((i=1; i<=node_count; i++)); do
        port=$((8000 + i - 1))
        pid=$(sudo lsof -t -i:$port 2>/dev/null)
        if [[ -n "$pid" ]]; then
            echo -e "🔴 Killing process on port $port (PID: $pid)"
            sudo kill -9 "$pid"
        fi
    done

    for node_path in "$HOME"/gaia-*; do
        if [[ -d "$node_path" ]]; then
            echo -e "🟢 Starting node: ${GREEN}$(basename $node_path)${NC}..."
            gaianet start --base "$node_path"
        fi
    done

    echo -e "✅ ${GREEN}All new nodes have been installed successfully!${NC}"
    sleep 2
}

show_info() {
    echo -e "📡 ${CYAN}Displaying Node Info...${NC}"
    base_dir="$HOME"

    for node_path in "$base_dir"/gaia-*; do
        if [[ -d "$node_path" ]]; then
            echo -e "ℹ️  ${GREEN}Node Info for: $(basename $node_path)${NC}"
            gaianet info --base "$node_path"
        fi
    done
}

while true; do
    show_menu
    read -p "Select an option (1-3): " choice
    case $choice in
        1) install_multiple_nodes ;;
        2) show_info ;;
        3) echo -e "🚪 ${RED}Exiting...${NC}"; exit 0 ;;
        *) echo -e "❌ ${RED}Invalid option. Please try again.${NC}" ;;
    esac
    echo ""
done
