#!/bin/bash
# Substitute template variables in release notes
# Usage: ./scripts/substitute-release-notes.sh <version> <network_name> <mintscan_chain_id> <calculated_height> <proposal_number> <previous_version> <release_tag>

set -e

VERSION="$1"
NETWORK_NAME="$2"
MINTSCAN_CHAIN_ID="$3"
CALCULATED_HEIGHT="$4"
PROPOSAL_NUMBER="$5"
PREVIOUS_VERSION="$6"
RELEASE_TAG="$7"

if [ -z "$VERSION" ] || [ -z "$NETWORK_NAME" ] || [ -z "$MINTSCAN_CHAIN_ID" ] || [ -z "$CALCULATED_HEIGHT" ] || [ -z "$PROPOSAL_NUMBER" ] || [ -z "$PREVIOUS_VERSION" ] || [ -z "$RELEASE_TAG" ]; then
  echo "Error: Missing required arguments"
  exit 1
fi

RELEASE_NOTES_FILE="release_notes/${VERSION}.md"

if [ -f "$RELEASE_NOTES_FILE" ]; then
  echo "Substituting template variables in: $RELEASE_NOTES_FILE"

  sed -i "s|{{NETWORK_NAME}}|$NETWORK_NAME|g" "$RELEASE_NOTES_FILE"
  sed -i "s|{{MINTSCAN_CHAIN_ID}}|$MINTSCAN_CHAIN_ID|g" "$RELEASE_NOTES_FILE"
  sed -i "s|{{CALCULATED_HEIGHT}}|$CALCULATED_HEIGHT|g" "$RELEASE_NOTES_FILE"
  sed -i "s|{{CALCULATED_PROPOSAL_NUMBER}}|$PROPOSAL_NUMBER|g" "$RELEASE_NOTES_FILE"
  sed -i "s|{{PREVIOUS_VERSION}}|$PREVIOUS_VERSION|g" "$RELEASE_NOTES_FILE"
  sed -i "s|{{RELEASE_TAG}}|$RELEASE_TAG|g" "$RELEASE_NOTES_FILE"
  sed -i "s|{{VERSION}}|$VERSION|g" "$RELEASE_NOTES_FILE"

  echo "✅ Release notes variables substituted successfully"
else
  echo "⚠️  Release notes file not found: $RELEASE_NOTES_FILE"
  exit 1
fi
