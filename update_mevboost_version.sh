#!/bin/bash

# Description: Update MEV-Boost to a version selected by the operator.

BASE_DIR=$HOME/git/ethpillar
source $BASE_DIR/functions.sh

setWhiptailColors

_platform=$(get_platform)  # Linux
_arch=$(get_arch)         # amd64 | arm64
_platform_lc=$(echo "${_platform}" | tr '[:upper:]' '[:lower:]')  # linux

# Fetch tag list
mapfile -t TAGS < <(curl -s "https://api.github.com/repos/flashbots/mev-boost/releases?per_page=10" | jq -r '.[].tag_name')

if [[ ${#TAGS[@]} -eq 0 ]]; then
  whiptail --title "Update MEV-Boost" --msgbox "Unable to fetch release list from GitHub." 8 60
  exit 1
fi

OPTIONS=()
for i in "${!TAGS[@]}"; do
  idx=$((i+1))
  OPTIONS+=("${idx}" "${TAGS[$i]}")
done

CHOICE=$(whiptail --title "Select MEV-Boost Version" --menu "Choose MEV-Boost version to install:" 0 0 0 "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

[[ -z "$CHOICE" ]] && exit 0

TAG="${TAGS[$((CHOICE-1))]}"
VER_NUM=$(echo "$TAG" | sed 's/^v//')

if ! whiptail --yesno "Update MEV-Boost to ${TAG}?" 8 60; then
  exit 0
fi

DOWNLOAD_URL="https://github.com/flashbots/mev-boost/releases/download/${TAG}/mev-boost_${VER_NUM}_${_platform_lc}_${_arch}.tar.gz"

echo "Downloading $DOWNLOAD_URL"
cd "$HOME"

wget -q --show-progress -O mev-boost.tar.gz "$DOWNLOAD_URL" || { whiptail --msgbox "Download failed." 8 60; exit 1; }

tar -xzf mev-boost.tar.gz -C "$HOME"
rm -f mev-boost.tar.gz LICENSE README.md 2>/dev/null

sudo systemctl stop mevboost 2>/dev/null
sudo mv -f "$HOME/mev-boost" /usr/local/bin/mev-boost
sudo chmod +x /usr/local/bin/mev-boost
sudo systemctl start mevboost 2>/dev/null

whiptail --title "Update MEV-Boost" --msgbox "MEV-Boost successfully updated to ${TAG}." 8 60 