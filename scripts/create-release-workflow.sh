#!/bin/bash
# Main orchestration script for creating release PRs
# This consolidates all the workflow steps into a single executable script
# Usage: ./scripts/create-release-workflow.sh

set -e

# ============================================================================
# Configuration from environment variables (set by GitHub Actions)
# ============================================================================
RELEASE_TAG="${RELEASE_TAG:-}"
XION_API_URL="${XION_API_URL:-}"
MINTSCAN_CHAIN_ID="${MINTSCAN_CHAIN_ID:-}"
NETWORK_NAME="${NETWORK_NAME:-}"
TARGET_BRANCH="${TARGET_BRANCH:-}"
DEPOSIT="${DEPOSIT:-1000000000uxion}"
EXPEDITED="${EXPEDITED:-false}"
PLACEHOLDER_CHECKSUM="${PLACEHOLDER_CHECKSUM:---ADD-HERE-YOUR-VALUE--}"
CLAUDE_API_KEY="${CLAUDE_API_KEY:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
RUN_NUMBER="${RUN_NUMBER:-0}"
COMMIT_SHA="${COMMIT_SHA:-}"

# ============================================================================
# Validate required inputs
# ============================================================================
if [ -z "$RELEASE_TAG" ] || [ -z "$XION_API_URL" ] || [ -z "$TARGET_BRANCH" ] || [ -z "$CLAUDE_API_KEY" ] || [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ Error: Missing required environment variables"
  echo "Required: RELEASE_TAG, XION_API_URL, TARGET_BRANCH, CLAUDE_API_KEY, GITHUB_TOKEN"
  exit 1
fi

echo "🚀 Starting release workflow for $RELEASE_TAG"
echo "================================================"

# ============================================================================
# Step 1: Setup release branch
# ============================================================================
echo ""
echo "📋 Step 1: Setting up release branch..."
source scripts/setup-release-branch.sh "$RELEASE_TAG"
echo "✅ Branch: $BRANCH_NAME, Version: $VERSION"

# ============================================================================
# Step 2: Calculate upgrade height
# ============================================================================
echo ""
echo "📋 Step 2: Calculating upgrade height..."
eval $(scripts/calculate-upgrade-height.sh "$XION_API_URL" | grep '^CALCULATED_HEIGHT=')
echo "✅ Upgrade height: $CALCULATED_HEIGHT"

# ============================================================================
# Step 3: Fetch release checksums
# ============================================================================
echo ""
echo "📋 Step 3: Fetching release checksums..."
eval $(scripts/fetch-release-checksums.sh "$RELEASE_TAG" "$PLACEHOLDER_CHECKSUM" | grep 'CHECKSUM=')
echo "✅ Checksums fetched"

# ============================================================================
# Step 4: Fetch GitHub comparison data
# ============================================================================
echo ""
echo "📋 Step 4: Fetching GitHub comparison data..."
eval $(scripts/fetch-github-comparison.sh "$RELEASE_TAG" "$GITHUB_TOKEN" | grep -E '^(PREVIOUS_VERSION|COMMIT_COUNT|FILES_CHANGED)=')
echo "✅ Comparison: $COMMIT_COUNT commits, $FILES_CHANGED files changed"

# ============================================================================
# Step 5: Generate release notes with Claude API
# ============================================================================
echo ""
echo "📋 Step 5: Generating release notes with Claude..."
scripts/generate-claude-notes.sh \
  ".github/workflows/prompts/claude-api-prompt.md" \
  "$RELEASE_TAG" \
  "$CALCULATED_HEIGHT" \
  "$PREVIOUS_VERSION" \
  "$CLAUDE_API_KEY"
echo "✅ Release notes generated"

# ============================================================================
# Step 6: Create release files
# ============================================================================
echo ""
echo "📋 Step 6: Creating release files..."
git restore .github/workflows/templates/release_notes_template.md 2>/dev/null || true
OUTPUT=$(scripts/create-release-pr.sh "$CALCULATED_HEIGHT" "$DEPOSIT" "$EXPEDITED" "$RELEASE_TAG")
CALCULATED_PROPOSAL_NUMBER=$(echo "$OUTPUT" | grep "^Proposal number:" | sed 's/Proposal number: //')
echo "✅ Proposal number: $CALCULATED_PROPOSAL_NUMBER"

# ============================================================================
# Step 7: Determine file paths
# ============================================================================
echo ""
echo "📋 Step 7: Determining file paths..."
eval $(scripts/determine-file-paths.sh "$RELEASE_TAG" | grep -E '^(PROPOSAL_FILE|RELEASE_FILE|RELEASE_NOTES_FILE|VERSION)=')
echo "✅ Files: $PROPOSAL_FILE, $RELEASE_FILE, $RELEASE_NOTES_FILE"

# ============================================================================
# Step 8: Substitute variables in release notes
# ============================================================================
echo ""
echo "📋 Step 8: Substituting template variables..."
scripts/substitute-release-notes.sh \
  "$VERSION" \
  "$NETWORK_NAME" \
  "$MINTSCAN_CHAIN_ID" \
  "$CALCULATED_HEIGHT" \
  "$CALCULATED_PROPOSAL_NUMBER" \
  "$PREVIOUS_VERSION" \
  "$RELEASE_TAG"

# ============================================================================
# Step 9: Generate PR body
# ============================================================================
echo ""
echo "📋 Step 9: Generating PR body..."
scripts/generate-pr-body.sh \
  "$VERSION" \
  "$CALCULATED_HEIGHT" \
  "$DEPOSIT" \
  "$EXPEDITED" \
  "$PROPOSAL_FILE" \
  "$RELEASE_FILE" \
  "$RELEASE_NOTES_FILE" \
  "$RELEASE_TAG" \
  "$COMMIT_COUNT" \
  "$FILES_CHANGED" \
  "$PREVIOUS_VERSION" \
  "$DARWIN_AMD64_CHECKSUM" \
  "$DARWIN_ARM64_CHECKSUM" \
  "$LINUX_AMD64_CHECKSUM" \
  "$LINUX_ARM64_CHECKSUM" \
  "$RUN_NUMBER" \
  "$COMMIT_SHA"

# ============================================================================
# Step 10: Commit and push PR
# ============================================================================
echo ""
echo "📋 Step 10: Committing and creating PR..."
scripts/commit-and-push-pr.sh \
  "$BRANCH_NAME" \
  "$TARGET_BRANCH" \
  "$RELEASE_TAG" \
  "$VERSION" \
  "$PROPOSAL_FILE" \
  "$RELEASE_FILE" \
  "$RELEASE_NOTES_FILE"

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "================================================"
echo "✅ Release workflow completed successfully!"
echo "================================================"
echo "Release: $RELEASE_TAG"
echo "Proposal: $PROPOSAL_FILE"
echo "Height: $CALCULATED_HEIGHT"
echo "Branch: $BRANCH_NAME → $TARGET_BRANCH"
