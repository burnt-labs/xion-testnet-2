#!/bin/bash
# Calculate upgrade block height (2 days from current block)
# Usage: ./scripts/calculate-upgrade-height.sh <api_url>

set -e

XION_API_URL="$1"

if [ -z "$XION_API_URL" ]; then
  echo "Error: XION_API_URL is required"
  exit 1
fi

# Get current block height and timestamp
echo "Fetching block data from: $XION_API_URL/cosmos/base/tendermint/v1beta1/blocks/latest"

API_RESPONSE=$(curl -s -X 'GET' "$XION_API_URL/cosmos/base/tendermint/v1beta1/blocks/latest" -H 'accept: application/json')
echo "API Response: $API_RESPONSE"

# Extract block height and time with error handling
CURRENT_BLOCK=$(echo "$API_RESPONSE" | jq -r '.block.header.height // empty')
CURRENT_TIME=$(echo "$API_RESPONSE" | jq -r '.block.header.time // empty')

echo "Current block: $CURRENT_BLOCK"
echo "Current time: $CURRENT_TIME"

# Check if we got valid data
if [ "$CURRENT_BLOCK" = "null" ] || [ -z "$CURRENT_BLOCK" ] || [ "$CURRENT_TIME" = "null" ] || [ -z "$CURRENT_TIME" ]; then
  echo "❌ ERROR: API returned null/empty values for block height or timestamp"
  echo "This indicates the chain is not running or the API is not accessible"
  echo "API Response was: $API_RESPONSE"
  echo "Expected format: .block.header.height and .block.header.time should not be null"
  exit 1
fi

# Get block from 10000 blocks ago
OLD_BLOCK=$((CURRENT_BLOCK - 10000))
OLD_BLOCK_INFO=$(curl -s -X 'GET' "$XION_API_URL/cosmos/base/tendermint/v1beta1/blocks/$OLD_BLOCK" -H 'accept: application/json' | jq -r '.block.header.time // empty')

echo "Old block ($OLD_BLOCK) time: $OLD_BLOCK_INFO"

# Check if old block data is valid
if [ "$OLD_BLOCK_INFO" = "null" ] || [ -z "$OLD_BLOCK_INFO" ]; then
  echo "❌ ERROR: Could not retrieve block data from $OLD_BLOCK blocks ago"
  echo "This indicates the chain history is not accessible or the block is too old"
  echo "Old block info was: $OLD_BLOCK_INFO"
  exit 1
fi

# Calculate average block time (in seconds)
CURRENT_TIMESTAMP=$(date -d "$CURRENT_TIME" +%s)
OLD_TIMESTAMP=$(date -d "$OLD_BLOCK_INFO" +%s)
TIME_DIFF=$((CURRENT_TIMESTAMP - OLD_TIMESTAMP))
AVERAGE_BLOCK_TIME=$(echo "scale=2; $TIME_DIFF / 10000" | bc)

echo "Average block time: ${AVERAGE_BLOCK_TIME} seconds"

# Calculate blocks for 2 days (172800 seconds)
BLOCKS_IN_2_DAYS=$(echo "scale=0; 172800 / $AVERAGE_BLOCK_TIME" | bc)

# Calculate target block height (round to nearest 1000)
TARGET_BLOCKS=$((BLOCKS_IN_2_DAYS + CURRENT_BLOCK))
ROUNDED_BLOCKS=$(( (TARGET_BLOCKS + 500) / 1000 * 1000 ))

echo "Blocks in 2 days: $BLOCKS_IN_2_DAYS"
echo "Target block height: $ROUNDED_BLOCKS"

# Output the result
echo "CALCULATED_HEIGHT=$ROUNDED_BLOCKS"
