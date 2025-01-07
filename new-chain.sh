#!/bin/bash

# This script creates a new genesis file for a chain by querying parameters from an existing chain
# and merging them into a new genesis file.
#
# Usage: ./new-chain.sh <chain-id>
#
# Requirements:
# - Chain daemon binary (xiond) must be in PATH
# - jq must be installed

set -euo pipefail

if [[ -z "$1" ]]; then
  echo "Usage: $0 <chain-id>"
  exit 1
fi

CHAIN_ID="$1"
DAEMON_NAME="xiond"  # Replace with your chain's DAEMON_NAME binary (e.g., gaiad)
RPC_URL="https://rpc.xion-testnet-1.burnt.com:443"

CONFIG_DIR="config"
GENTX_DIR="gentx"
GENESIS_FILE="${GENTX_DIR}/gentx-genesis.json"
MODULES=(
  "abstractaccount"
  "auth"
  "bank"
  # "consensus" # key exists but default is null, so we don't need to query it
  "distribution"
  "globalfee"
  "gov"
  "jwk"
  "mint"
  "packetforward"
  "slashing"
  "staking"
  "tokenfactory"
  "wasm"
)

# Temporary directory for intermediate files
tmp_dir=$(mktemp -d -t xion-testnet-2)
trap 'rm -rf $tmp_dir' EXIT

initialize_directories() {
  echo "Initializing directories..."
  mkdir -p $CONFIG_DIR $GENTX_DIR
}

initialize_app_state() {
  echo "Initializing app_state..."
  echo "{}" > "$tmp_dir/app_state.json"
}

query_module_params() {
  local module=$1
  local params_file="$tmp_dir/${module}_params.json"

  echo "Querying $module params..."
  case $module in
  "abstractaccount")
    $DAEMON_NAME query abstract-account params --node $RPC_URL --output json > "$params_file" || echo "{}" > "$params_file"
    ;;
  *)
    $DAEMON_NAME query $module params --node $RPC_URL --output json > "$params_file" || echo "{}" > "$params_file"
    ;;
  esac
}

merge_params_into_app_state() {
  local module=$1
  local params_file="$tmp_dir/${module}_params.json"

  echo "Merging parameters for $module into app_state..."
  jq --arg module "$module" --slurpfile params "$params_file" \
    '.app_state[$module] = $params[0]' "$tmp_dir/app_state.json" > "$tmp_dir/app_state_tmp.json"
  mv "$tmp_dir/app_state_tmp.json" "$tmp_dir/app_state.json"
}

create_genesis_file() {
  $DAEMON_NAME init $CHAIN_ID --default-denom uxion --chain-id $CHAIN_ID --home $(pwd)
  jq '.app_state = (.app_state + input.app_state)' "$CONFIG_DIR/genesis.json" "$tmp_dir/app_state.json" > "$GENESIS_FILE"
}

validate_genesis_file() {
  echo "Validating new genesis file..."
  $DAEMON_NAME genesis validate-genesis $GENESIS_FILE --home $(pwd)
}

modify_genesis_file() {
  echo "Modifying genesis file..."
  jq '.app_state.feeabs.params.native_ibced_in_osmosis = "" |
      .app_state.feeabs.params.chain_name = "" |
      .app_state.abstractaccount.params.allow_all_code_ids = false |
      .app_state.abstractaccount.params.allowed_code_ids = ["1"]' "$GENESIS_FILE" > "$GENESIS_FILE.tmp"
  mv "$GENESIS_FILE.tmp" "$GENESIS_FILE"
}

cleanup() {
  rm config/genesis.json config/node_key.json config/priv_validator_key.json
  rm -rf data $tmp_dir
}

main() {
  initialize_directories
  initialize_app_state
  create_genesis_file

  for module in "${MODULES[@]}"; do
    query_module_params $module
    merge_params_into_app_state $module
  done

  modify_genesis_file
  validate_genesis_file
  cleanup

  echo "Done. New genesis file is located at $GENESIS_FILE."
}

main
