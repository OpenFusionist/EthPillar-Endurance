#!/bin/bash

# Description: Update Nimbus consensus (beacon node & validator) to user-selected version.

BASE_DIR=$HOME/git/ethpillar
source $BASE_DIR/functions.sh

setWhiptailColors

_platform=$(get_platform)   # Linux
_arch=$(get_arch)           # amd64 | arm64

# Fetch recent release tags
mapfile -t TAGS < <(curl -s "https://api.github.com/repos/status-im/nimbus-eth2/releases?per_page=10" | jq -r '.[].tag_name')

if [[ ${#TAGS[@]} -eq 0 ]]; then
  whiptail --title "Update Nimbus" --msgbox "Unable to fetch releases from GitHub." 8 60
  exit 1
fi

OPTIONS=()
for i in "${!TAGS[@]}"; do
  idx=$((i+1))
  OPTIONS+=("${idx}" "${TAGS[$i]}")
done

CHOICE=$(whiptail --title "Select Nimbus Version" \
                 --menu "Choose Nimbus version to install:" \
                 0 0 0 \
                 "${OPTIONS[@]}" \
                 3>&1 1>&2 2>&3)

[[ -z "$CHOICE" ]] && exit 0

TAG="${TAGS[$((CHOICE-1))]}"    

if ! whiptail --yesno "Update Nimbus to ${TAG}?" 8 60; then
  exit 0
fi

RELEASE_URL="https://api.github.com/repos/status-im/nimbus-eth2/releases/tags/${TAG}"

DOWNLOAD_URL=$(curl -s "$RELEASE_URL" | jq -r ".assets[] | select(.name) | .browser_download_url" | grep --ignore-case "_${_platform}_${_arch}.*.tar.gz$")

if [[ -z "$DOWNLOAD_URL" ]]; then
  whiptail --title "Update Nimbus" --msgbox "Could not find suitable binary for ${_platform}/${_arch} in ${TAG}." 8 60
  exit 1
fi

echo "Downloading $DOWNLOAD_URL"
cd "$HOME"
wget -q --show-progress -O nimbus.tar.gz "$DOWNLOAD_URL" || { whiptail --msgbox "Download failed." 8 60; exit 1; }

tar -xzf nimbus.tar.gz -C "$HOME"
rm -f nimbus.tar.gz

# Locate extracted directory
EXTRACTED_DIR=$(ls -d nimbus-eth2_${_platform}_${_arch}* 2>/dev/null | head -1)

if [[ -z "$EXTRACTED_DIR" ]]; then
  whiptail --msgbox "Extraction failed to find Nimbus binaries." 8 60
  exit 1
fi

sudo systemctl stop consensus 2>/dev/null
sudo systemctl stop validator 2>/dev/null

sudo rm -f /usr/local/bin/nimbus_beacon_node /usr/local/bin/nimbus_validator_client
sudo mv "$EXTRACTED_DIR"/build/nimbus_beacon_node /usr/local/bin
sudo mv "$EXTRACTED_DIR"/build/nimbus_validator_client /usr/local/bin
sudo chmod +x /usr/local/bin/nimbus_beacon_node /usr/local/bin/nimbus_validator_client

sudo systemctl start consensus 2>/dev/null
sudo systemctl start validator 2>/dev/null

rm -rf "$EXTRACTED_DIR"

whiptail --title "Update Nimbus" --msgbox "Nimbus successfully updated to ${TAG}." 8 60 