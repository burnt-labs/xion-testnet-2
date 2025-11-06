#!/bin/bash
# Fetch GitHub comparison data between releases
# Usage: ./scripts/fetch-github-comparison.sh <release_tag> <github_token>

set -e

RELEASE_TAG="$1"
GITHUB_TOKEN="$2"

if [ -z "$RELEASE_TAG" ] || [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: RELEASE_TAG and GITHUB_TOKEN are required"
  exit 1
fi

# Extract version number from release tag
CURRENT_VERSION="$RELEASE_TAG"
# Extract major version number and calculate previous version
CURRENT_MAJOR=$(echo "$CURRENT_VERSION" | sed 's/v\([0-9]*\)\.0\.0/\1/')
PREVIOUS_MAJOR=$((CURRENT_MAJOR - 1))

PREVIOUS_VERSION="v${PREVIOUS_MAJOR}.0.0"

echo "Current version: $CURRENT_VERSION"
echo "Previous version: $PREVIOUS_VERSION"

# Check if current version (future release) exists in the repository
CURRENT_TAG_EXISTS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/burnt-labs/xion/git/refs/tags/$CURRENT_VERSION" | \
  jq -r '.ref // "not_found"')

if [[ "$CURRENT_TAG_EXISTS" == "not_found" ]]; then
  echo "⚠️  Current version $CURRENT_VERSION doesn't exist yet (future release)"
  echo "📝 Creating placeholder comparison data for future release documentation"

  # Create placeholder comparison data for future release
  COMPARISON_DATA='{"total_commits": "TBD", "files": [], "commits": [], "ahead_by": "TBD", "message": "Future release - comparison will be available when release is published"}'
  COMMIT_COUNT="TBD"
  FILES_CHANGED="TBD"

  echo "-- Using placeholder data for future release --"
else
  # Get GitHub comparison data for existing releases
  COMPARISON_URL="https://api.github.com/repos/burnt-labs/xion/compare/$PREVIOUS_VERSION...$CURRENT_VERSION"
  echo "Fetching comparison from: $COMPARISON_URL"

  # Fetch the comparison data
  COMPARISON_DATA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$COMPARISON_URL")

  # Check if the API response contains an error
  ERROR_MESSAGE=$(echo "$COMPARISON_DATA" | jq -r '.message // empty')

  if [[ "$ERROR_MESSAGE" == "Not Found" ]]; then
    echo "⚠️  Previous version $PREVIOUS_VERSION not found in GitHub"
    echo "📝 One of two versions doesn't exist"

    # Create empty comparison data
    COMPARISON_DATA='{"total_commits": 0, "files": [], "commits": []}'
    COMMIT_COUNT=0
    FILES_CHANGED=0

    echo "-- Using empty comparison data --"
  else
    echo "✅ Successfully fetched comparison data"

    # Extract key information
    COMMIT_COUNT=$(echo "$COMPARISON_DATA" | jq -r '.total_commits // 0')
    FILES_CHANGED=$(echo "$COMPARISON_DATA" | jq -r '.files | length // 0')
  fi
fi

echo "Commits: $COMMIT_COUNT"
echo "Files changed: $FILES_CHANGED"

# Save comparison data to file for Claude API (even if placeholder)
echo "$COMPARISON_DATA" > comparison_data.json

# Output results
echo "PREVIOUS_VERSION=$PREVIOUS_VERSION"
echo "COMMIT_COUNT=$COMMIT_COUNT"
echo "FILES_CHANGED=$FILES_CHANGED"
