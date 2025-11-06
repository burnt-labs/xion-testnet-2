#!/bin/bash
# Setup release branch for PR creation
# Usage: ./scripts/setup-release-branch.sh <release_tag>

set -e

RELEASE_TAG="$1"

if [ -z "$RELEASE_TAG" ]; then
  echo "Error: RELEASE_TAG is required"
  exit 1
fi

# Extract version from RELEASE_TAG and set branch name
VERSION_NUM=$(echo "$RELEASE_TAG" | sed 's/v\([0-9]*\)\.0\.0/\1/')
VERSION="v${VERSION_NUM}"
BRANCH_NAME="release/$RELEASE_TAG"

echo "VERSION=$VERSION"
echo "BRANCH_NAME=$BRANCH_NAME"

# Set up git config
git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"

# Fetch all remote branches to ensure we have latest refs
git fetch origin

# Check if remote branch exists and handle accordingly
if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then
  echo "Remote branch $BRANCH_NAME exists, checking out and pulling latest changes"

  # Check if local branch exists
  if git show-ref --verify --quiet refs/heads/"$BRANCH_NAME"; then
    echo "Local branch exists, switching to it"
    git checkout "$BRANCH_NAME"
  else
    echo "Local branch doesn't exist, creating from remote"
    git checkout -b "$BRANCH_NAME" origin/"$BRANCH_NAME"
  fi

  # Pull latest changes from remote to avoid conflicts
  git pull origin "$BRANCH_NAME"

else
  echo "Remote branch $BRANCH_NAME doesn't exist, creating new branch"
  git checkout -b "$BRANCH_NAME"
fi
