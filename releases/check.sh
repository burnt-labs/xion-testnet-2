#!/usr/bin/env bash

set -euo pipefail

# Create a temporary directory
temp_dir=$(mktemp -d)
cd "$temp_dir"

# Function to download and verify
verify_checksum() {
  local url=$1
  local expected_checksum=$2
  
  # Extract filename from URL (before the '?')
  local filename=$(echo "$url" | cut -d'?' -f1 | awk -F'/' '{print $NF}')
  
  echo "Downloading $filename..."
  curl -sSL -O "${url%\?*}" 
  
  # Calculate actual checksum
  local actual_checksum=$(sha256sum "$filename" | cut -d' ' -f1)
  
  echo "Verifying checksum for $filename..."
  if [ "$actual_checksum" = "$expected_checksum" ]; then
    echo "✅ Checksum verified for $filename"
  else
    echo "❌ Checksum verification failed for $filename"
    echo "Expected: $expected_checksum"
    echo "Got:      $actual_checksum"
  fi
  echo
}

# Process each binary from JSON file
# Read the JSON file and process each platform
jq -r '.binaries | to_entries[] | "\(.key) \(.value)"' | while read -r platform url; do
    checksum=$(echo "$url" | cut -d':' -f3)
    url=${url%:*}  # Remove checksum part from URL
    if [ -n "$url" ] && [ -n "$checksum" ]; then
      echo "Processing $platform..."
      verify_checksum "$url" "$checksum" 
    fi
  done

# Cleanup
cd - > /dev/null
rm -rf "$temp_dir"
