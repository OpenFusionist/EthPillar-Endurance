#!/bin/bash
# Update Endurance network genesis and config files


set -e

# Load helper functions and environment variables
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${BASE_DIR}/functions.sh"

getNetwork

case "$NETWORK" in
  "Endurance Mainnet")
    CONFIG_URL="https://github.com/OpenFusionist/network_config"
    ;;
  "Endurance Devnet")
    CONFIG_URL="https://github.com/OpenFusionist/devnet_network_config"
    ;;
  *)
    echo "[WARN] Current network ($NETWORK) is not Endurance. Nothing to update."
    exit 0
    ;;
esac

# Reuse common download logic
runScript download_endurance_config.sh "$CONFIG_URL"

# Prompt for service restart
if whiptail --title "Restart clients" --yesno "Configuration updated. Restart consensus & execution clients now?" 8 78; then
  sudo service consensus restart || true
  sudo service execution restart || true
fi

exit 0 