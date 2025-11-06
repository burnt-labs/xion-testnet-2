#!/bin/bash
# Fetch release checksums from GitHub releases
# Usage: ./scripts/fetch-release-checksums.sh <release_tag> <placeholder_checksum>

set -e

RELEASE_TAG="$1"
PLACEHOLDER_CHECKSUM="${2:---ADD-HERE-YOUR-VALUE--}"

if [ -z "$RELEASE_TAG" ]; then
  echo "Error: RELEASE_TAG is required"
  exit 1
fi

# Construct the checksums URL for the release
CHECKSUMS_URL="https://github.com/burnt-labs/xion/releases/download/$RELEASE_TAG/xiond-$RELEASE_TAG-checksums.txt"
echo "Fetching checksums from: $CHECKSUMS_URL"

# Try to fetch the checksums file
CHECKSUMS_RESPONSE=$(curl -s -w "%{http_code}" "$CHECKSUMS_URL" -o checksums_temp.txt)
HTTP_CODE="${CHECKSUMS_RESPONSE: -3}"

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ Successfully fetched checksums for $RELEASE_TAG"

  # Parse the checksums file and extract values
  CHECKS_FILE="checksums_temp.txt"

  # Extract checksums for different platforms
  DARWIN_AMD64_CHECKSUM=$(grep "darwin_amd64.tar.gz" "$CHECKS_FILE" | awk '{print $1}')
  DARWIN_ARM64_CHECKSUM=$(grep "darwin_arm64.tar.gz" "$CHECKS_FILE" | awk '{print $1}')
  LINUX_AMD64_CHECKSUM=$(grep "linux_amd64.tar.gz" "$CHECKS_FILE" | awk '{print $1}')
  LINUX_ARM64_CHECKSUM=$(grep "linux_arm64.tar.gz" "$CHECKS_FILE" | awk '{print $1}')

  echo "DARWIN_AMD64_CHECKSUM=$DARWIN_AMD64_CHECKSUM"
  echo "DARWIN_ARM64_CHECKSUM=$DARWIN_ARM64_CHECKSUM"
  echo "LINUX_AMD64_CHECKSUM=$LINUX_AMD64_CHECKSUM"
  echo "LINUX_ARM64_CHECKSUM=$LINUX_ARM64_CHECKSUM"

  echo "✅ Using real checksums:"
  echo "  Darwin AMD64: $DARWIN_AMD64_CHECKSUM"
  echo "  Darwin ARM64: $DARWIN_ARM64_CHECKSUM"
  echo "  Linux AMD64: $LINUX_AMD64_CHECKSUM"
  echo "  Linux ARM64: $LINUX_ARM64_CHECKSUM"

else
  echo "⚠️  Checksums file not found for $RELEASE_TAG (HTTP $HTTP_CODE)"
  if [ "$HTTP_CODE" = "404" ]; then
    echo "📝 This appears to be a future release - checksums will be available when the release is published"
  fi
  echo "📝 Using placeholder values for now"

  # Use placeholder values
  echo "DARWIN_AMD64_CHECKSUM=$PLACEHOLDER_CHECKSUM"
  echo "DARWIN_ARM64_CHECKSUM=$PLACEHOLDER_CHECKSUM"
  echo "LINUX_AMD64_CHECKSUM=$PLACEHOLDER_CHECKSUM"
  echo "LINUX_ARM64_CHECKSUM=$PLACEHOLDER_CHECKSUM"

  echo "📝 Using placeholder checksums (will be updated when release is available)"
fi

# Clean up temporary file
rm -f checksums_temp.txt
