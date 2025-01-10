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
RPC_URL="https://rpc.xion-mainnet-1.burnt.com:443"
CODE_IDS=("1" "")
GENESIS_TIME="2025-01-28T00:00:00.000000Z"

CONFIG_DIR="config"
GENTX_DIR="$CONFIG_DIR/gentx"
MODULES=(
  "abstractaccount"
  "auth"
  "bank"
  "consensus" 
  "distribution"
  "globalfee"
  "gov"
  "jwk"
  "mint"
  "slashing" 
  "staking" 
  "tokenfactory"
  "wasm"
)

# Temporary directory for intermediate files
TMP_DIR=$(mktemp -d -t xion-testnet-2)
trap 'rm -rf $TMP_DIR' EXIT

initialize_directories() {
  echo "Initializing directories..."
  mkdir -p $CONFIG_DIR $GENTX_DIR
  touch $GENTX_DIR/.gitkeep
}

merge_params_into_genesis() {
  local module=$1
  local params
  local jq_script

  case "$module" in
    "abstractaccount")
      jq_script='.app_state["abstractaccount"]["params"] += $params'
      module="abstract-account"
      ;;
    "consensus")
      jq_script='.consensus["params"]["block"] = $params["params"]["block"]' 
      ;;
    "globalfee")
      jq_script='.app_state[$module]["params"]["minimum_gas_prices"] = $params["minimum_gas_prices"]'
      ;;
    *)
      jq_script='.app_state[$module]["params"] = (.app_state[$module]["params"] + $params["params"])'
      ;;
  esac

  echo "Querying $module params..."
  params="$($DAEMON_NAME query $module params --node $RPC_URL --output json || echo "{}")"

  jq --arg module "$module" --argjson params "$params" \
    "$jq_script" "$CONFIG_DIR/genesis.json" > "$TMP_DIR/genesis.json"

  cp $TMP_DIR/genesis.json $CONFIG_DIR/genesis.json
}

create_genesis_file() {
  $DAEMON_NAME init moniker --default-denom uxion --chain-id $CHAIN_ID --home $(pwd)
  rm $CONFIG_DIR/node_key.json $CONFIG_DIR/priv_validator_key.json
  mv $CONFIG_DIR/genesis.json $CONFIG_DIR/genesis.json
}

 add_code_ids(){
  local code_id=1
  for code_id in "${CODE_IDS[@]}"; do
    params="$($DAEMON_NAME query wasm list-code --node $RPC_URL --output json)"
    code_bytes=$(xiond query wasm code >(base64) --node $RPC_URL --output raw)
    jq --argjson code_bytes "$code_bytes" '.app_state.wasm.codes += [{"code_id": $code_id, "code_bytes": $code_bytes, "creator": "creator_address_here", "instantiate_permission": {"permission": "Everybody", "address": "", "addresses": []}}]' "$CONFIG_DIR/genesis.json" > "$TMP_DIR/genesis.json"
    cp $TMP_DIR/genesis.json $CONFIG_DIR/genesis.json
  done
}

validate_genesis_file() {
  echo "Validating new genesis file..."
  $DAEMON_NAME genesis validate-genesis $CONFIG_DIR/genesis.json --home $(pwd) --trace
}

modify_genesis_file() {
  echo "Modifying genesis file..."
  jq ".genesis_time = \"$GENESIS_TIME\" |
      .app_state.abstractaccount.params.allow_all_code_ids = false |
      .app_state.abstractaccount.params.allowed_code_ids = [\"1\"] |
      .app_state.feeabs.params.native_ibced_in_osmosis = \"\" |
      .app_state.feeabs.params.chain_name = \"\" |
      .app_state.feeabs.epochs = [] |
      .app_state.gov.params.expedited_voting_period = \"3600s\"" \
      $CONFIG_DIR/genesis.json > $TMP_DIR/genesis.json
  mv $TMP_DIR/genesis.json "$CONFIG_DIR/genesis.json"
}

modify_app_toml() {
  echo "Modifying app.toml..."
  # modify the app.toml
  sed -e 's/localhost/0.0.0.0/' \
      -e 's/^minimum-gas-prices =.*/minimum-gas-prices = "0.001xion"/' \
      -e 's/enabled-unsafe-cors = false/enabled-unsafe-cors = true/' \
      -e '/^\[api\]/,/\[rosetta\]/ s|^enable *=.*|enable = true|' \
      -e '/^\[api\]/,/\[rosetta\]/ s|^swagger *=.*|swagger = true|' \
      $CONFIG_DIR/app.toml > $TMP_DIR/app.toml
  mv $TMP_DIR/app.toml $CONFIG_DIR/app.toml
}

modify_config_toml() {
  echo "Modifying config.toml..."
  # modify the config.toml
  sed -e 's/^laddr *=\s*\"tcp:\/\/127.0.0.1/laddr = \"tcp:\/\/0.0.0.0/' \
      -e 's/^cors_allowed_origins *=.*/cors_allowed_origins = ["*"]/' \
      -e 's/^addr_book_strict *=.*/addr_book_strict = false/' \
      $CONFIG_DIR/config.toml > $TMP_DIR/config.toml
  mv $TMP_DIR/config.toml $CONFIG_DIR/config.toml
}   

cleanup() {
  rm -rf data $TMP_DIR
}

main() {
  initialize_directories
  create_genesis_file

  for module in "${MODULES[@]}"; do
    merge_params_into_genesis $module
  done
  add_code_ids
  
  modify_genesis_file
  validate_genesis_file

  modify_app_toml
  modify_config_toml
  cleanup

  echo "Done. New genesis file is located at $CONFIG_DIR/genesis.json."
}

main
