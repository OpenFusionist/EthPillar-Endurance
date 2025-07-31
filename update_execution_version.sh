#!/bin/bash

# Description: Update Reth execution client to a user-specified version
# This script fetches the latest release tags from GitHub and lets the
# operator pick which one to install.

BASE_DIR=$HOME/git/ethpillar
source $BASE_DIR/functions.sh

setWhiptailColors

# Determine platform / architecture
_platform=$(get_platform)   # Linux
_arch=$(get_arch)           # amd64 | arm64

# Convert architecture for reth asset naming
[[ "${_arch}" == "amd64" ]] && _architecture="x86_64" || _architecture="aarch64"

# Retrieve the 20 most recent release tags for Reth
mapfile -t TAGS < <(curl -s "https://api.github.com/repos/paradigmxyz/reth/releases?per_page=10" | jq -r '.[].tag_name')

if [[ ${#TAGS[@]} -eq 0 ]]; then
  whiptail --title "Update Reth" --msgbox "Unable to fetch release list from GitHub." 8 60
  exit 1
fi

# Build whiptail menu options
OPTIONS=()
for i in "${!TAGS[@]}"; do
  idx=$((i+1))
  OPTIONS+=("${idx}" "${TAGS[$i]}")
done

CHOICE=$(whiptail --title "Select Reth Version" \
                 --menu "Choose the Reth version to install:" \
                 0 0 0 \
                 "${OPTIONS[@]}" \
                 3>&1 1>&2 2>&3)

if [[ -z "$CHOICE" ]]; then
  exit 0  # user cancelled
fi

TAG="${TAGS[$((CHOICE-1))]}"

echo "Selected tag: $TAG"

if ! whiptail --yesno "Update Reth to version ${TAG}?" 8 60; then
  exit 0
fi

# Construct download URL
DOWNLOAD_URL="https://github.com/paradigmxyz/reth/releases/download/${TAG}/reth-${TAG}-${_architecture}-unknown-linux-gnu.tar.gz"

echo "Downloading $DOWNLOAD_URL"
cd "$HOME"

wget -q --show-progress -O reth.tar.gz "$DOWNLOAD_URL" || {
  whiptail --title "Update Reth" --msgbox "Download failed. Aborting." 8 60
  exit 1
}

tar -xzf reth.tar.gz -C "$HOME" || {
  whiptail --title "Update Reth" --msgbox "Extraction failed. Aborting." 8 60
  rm -f reth.tar.gz
  exit 1
}
rm -f reth.tar.gz

# Stop service, replace binary, restart
sudo systemctl stop execution
sudo mv -f "$HOME/reth" /usr/local/bin/reth
sudo chmod +x /usr/local/bin/reth
sudo systemctl start execution

whiptail --title "Update Reth" --msgbox "Reth successfully updated to ${TAG}." 8 60 