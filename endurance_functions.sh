# Contains custom functions for Endurance.

# Download Endurance network config repo, unpack if needed, copy artifacts.
# Usage: download_endurance_config <git_repo_url>
download_endurance_config() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: download_endurance_config <git_repo_url>" >&2
    return 1
  fi

  local REPO_URL="$1"
  local TARGET_DIR="/opt/ethpillar/el-cl-genesis-data"
  local TMP_DIR
  TMP_DIR="$(mktemp -d -t network_config-XXXXXXXX)"

  echo "[INFO] Cloning $REPO_URL to $TMP_DIR"

  git clone --depth 1 "$REPO_URL" "$TMP_DIR"

  if [[ -f "$TMP_DIR/decompress.sh" ]]; then
    chmod +x "$TMP_DIR/decompress.sh"
    echo "[INFO] Running decompress.sh"
    (cd "$TMP_DIR" && bash ./decompress.sh)
  fi

  sudo mkdir -p "$TARGET_DIR"

  echo "[INFO] Copying files to $TARGET_DIR"
  for f in genesis.json genesis.ssz config.yaml deploy_block.txt deposit_contract.txt deposit_contract_block.txt deposit_contract_block_hash.txt; do
    if [[ -f "$TMP_DIR/$f" ]]; then
      sudo cp "$TMP_DIR/$f" "$TARGET_DIR/"
      echo "[INFO] Copied $f"
    fi
  done

  rm -rf "$TMP_DIR"

  echo "[SUCCESS] Endurance config updated."
}


# Auto-update Endurance network config if outdated
auto_update_endurance_config() {
  local CONFIG_FILE="/opt/ethpillar/el-cl-genesis-data/config.yaml"
  local NETWORK_CONFIG_URL="https://github.com/OpenFusionist/network_config"
  local PECTRA_KEYWORD="ELECTRA_FORK_EPOCH: 120150"

  if [[ ! -f "$CONFIG_FILE" ]] || ! grep -q "$PECTRA_KEYWORD" "$CONFIG_FILE"; then
      echo "[INFO] Endurance config outdated or missing. Fetching latest..."
      download_endurance_config "$NETWORK_CONFIG_URL"
  fi
}