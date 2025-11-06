#!/bin/bash
# Determine file paths for proposal, release, and release notes
# Usage: ./scripts/determine-file-paths.sh <release_tag>

set -e

RELEASE_TAG="$1"

if [ -z "$RELEASE_TAG" ]; then
  echo "Error: RELEASE_TAG is required"
  exit 1
fi

# Calculate version
VERSION_NUM=$(echo "$RELEASE_TAG" | sed 's/v\([0-9]*\)\.0\.0/\1/')
VERSION="v${VERSION_NUM}"

# Find or determine proposal file
ACTUAL_PROPOSAL_FILE=$(find proposals/ -name "*-upgrade-${VERSION}.json" 2>/dev/null | head -1)

if [ -z "$ACTUAL_PROPOSAL_FILE" ]; then
  # Fallback: predict the next number if no file found yet
  LATEST_PROPOSAL=$(ls proposals/ 2>/dev/null | grep -E '^[0-9]{3}-upgrade-v[0-9]+\.json$' | sort -V | tail -1)

  if [ -z "$LATEST_PROPOSAL" ]; then
    NEXT_NUM="001"
  else
    CURRENT_NUM=$(echo $LATEST_PROPOSAL | cut -d'-' -f1)
    NEXT_NUM=$(printf "%03d" $((10#$CURRENT_NUM + 1)))
  fi

  ACTUAL_PROPOSAL_FILE="proposals/${NEXT_NUM}-upgrade-${VERSION}.json"
fi

# Output the file paths
echo "PROPOSAL_FILE=$ACTUAL_PROPOSAL_FILE"
echo "RELEASE_FILE=releases/$VERSION.json"
echo "RELEASE_NOTES_FILE=release_notes/$VERSION.md"
echo "VERSION=$VERSION"
