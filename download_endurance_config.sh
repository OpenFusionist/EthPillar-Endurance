#!/bin/bash
# download_endurance_config.sh
# Clone Endurance network config repo, unpack if needed, copy artifacts.
# Usage: download_endurance_config.sh <git_repo_url>

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <git_repo_url>" >&2
  exit 1
fi

REPO_URL="$1"
TARGET_DIR="/opt/ethpillar/el-cl-genesis-data"
TMP_DIR="$(mktemp -d -t network_config-XXXXXXXX)"

echo "[INFO] Cloning $REPO_URL to $TMP_DIR"

git clone --depth 1 "$REPO_URL" "$TMP_DIR"

# Run decompress script if present
if [[ -f "$TMP_DIR/decompress.sh" ]]; then
  chmod +x "$TMP_DIR/decompress.sh"
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