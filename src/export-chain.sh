#!/bin/bash

# This script creates a new genesis file for a chain by querying parameters from an existing chain
# and merging them into a new genesis file.
#
# Usage: ./new-chain.sh <chain-id>
#
# Requirements:
# - Chain daemon binary (xiond) must be in PATH
# - jq must be installed

set -Eeuo pipefail

if [[ -z "$1" ]]; then
  echo "Usage: $0 <chain-id>"
  exit 1
fi

SCRIPTS_DIR=$(dirname "$0")

source "$SCRIPTS_DIR/$1.env"

CONFIG_DIR="config"
GENTX_DIR="$CONFIG_DIR/gentx"
MODULES=(
  "abstractaccount"
  "auth"
  "bank"
  "bank_denoms_metadata"
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
  local query="params"

  case "$module" in
    "abstractaccount")
      jq_script='.app_state["abstractaccount"]["params"] += $params'
      module="abstract-account"
      ;;
    "bank_denoms_metadata")
      module="bank"
      query="denoms-metadata"
      jq_script='.app_state[$module]["denom_metadata"] = [$params["metadatas"][] | select(.name == "xion")]'
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


  echo "Querying $module $query..."
  params="$($DAEMON_NAME query $module $query --node $RPC_URL --output json || echo "{}")"

  jq --arg module "$module" --argjson params "$params" \
    "$jq_script" "$CONFIG_DIR/genesis.json" > "$TMP_DIR/genesis.json"

  cp $TMP_DIR/genesis.json $CONFIG_DIR/genesis.json
}

create_genesis_file() {
  $DAEMON_NAME init moniker --default-denom uxion --chain-id $CHAIN_ID --home $(pwd)
  rm $CONFIG_DIR/node_key.json $CONFIG_DIR/priv_validator_key.json
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

add_genesis_account() {
  local account_number=$1
  local addr=$2
  modify_genesis_jq --arg execute add_genesis_account --argjson vars "{\"account_number\": $account_number, \"addr\": \"$addr\"}"
}

add_genesis_balance() {
  local addr=$1
  local coins=$2
  modify_genesis_jq --arg execute add_genesis_balance --argjson vars "{\"addr\": \"$addr\", \"coins\": $coins}"
}

add_genesis_accounts() {
  local account_number=0
  for addr in ${ACCOUNTS[@]}; do
    add_genesis_account $account_number $addr
    add_genesis_balance $addr "[{\"denom\": \"${DEFAULT_DENOM}\", \"amount\": \"${ACCOUNT_TOKENS}\"}]"
    ((account_number++))
  done
  for addr in ${VALIDATORS[@]}; do
    add_genesis_account $account_number $addr
    add_genesis_balance $addr "[{\"denom\": \"${DEFAULT_DENOM}\", \"amount\": \"${VALIDATOR_TOKENS}\"}]"
    ((account_number++))
  done  
}

modify_genesis_jq() {
  $SCRIPTS_DIR/modify-genesis.jq "$@" -f $CONFIG_DIR/genesis.json > $TMP_DIR/genesis.json &&
  mv $TMP_DIR/genesis.json $CONFIG_DIR/genesis.json
}

modify_genesis_file() {
  if [[ ${SOURCE_CHAIN_ID} == "xion-testnet-1" ]]; then
    echo "Modifying genesis file..."
    modify_genesis_jq --arg execute modify_genesis_xion_testnet_1 --argjson vars "{}"
  else
    modify_genesis_jq --arg execute modify_genesis --argjson vars "{}"
  fi
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
  # # add_code_ids
  
  add_genesis_accounts
  modify_genesis_file
  validate_genesis_file

  modify_app_toml
  modify_config_toml
  cleanup

  echo "Done. New genesis file is located at $CONFIG_DIR/genesis.json."
}

main
