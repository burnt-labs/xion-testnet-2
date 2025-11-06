#!/bin/bash
# Commit changes and create/update pull request
# Usage: ./scripts/commit-and-push-pr.sh <branch_name> <target_branch> <release_tag> <version> <proposal_file> <release_file> <release_notes_file>

set -e

BRANCH_NAME="$1"
TARGET_BRANCH="$2"
RELEASE_TAG="$3"
VERSION="$4"
PROPOSAL_FILE="$5"
RELEASE_FILE="$6"
RELEASE_NOTES_FILE="$7"

if [ -z "$BRANCH_NAME" ] || [ -z "$TARGET_BRANCH" ] || [ -z "$RELEASE_TAG" ] || [ -z "$VERSION" ] || [ -z "$PROPOSAL_FILE" ] || [ -z "$RELEASE_FILE" ] || [ -z "$RELEASE_NOTES_FILE" ]; then
  echo "Error: Missing required arguments"
  exit 1
fi

# Stage and commit changes
CHANGES_DETECTED=false
COMMIT_MESSAGE_PARTS=()

for file in "$PROPOSAL_FILE" "$RELEASE_FILE" "$RELEASE_NOTES_FILE"; do
  if [ -f "$file" ]; then
    if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
      if ! git diff --quiet "$file" 2>/dev/null; then
        git add "$file"
        CHANGES_DETECTED=true
        COMMIT_MESSAGE_PARTS+=("- Updated: $file")
      fi
    else
      git add "$file"
      CHANGES_DETECTED=true
      COMMIT_MESSAGE_PARTS+=("- Created: $file")
    fi
  fi
done

# Create commit message
if [ "$CHANGES_DETECTED" = true ]; then
  {
    echo "Added release $RELEASE_TAG and historical release notes"
    echo ""
    printf '%s\n' "${COMMIT_MESSAGE_PARTS[@]}"
  } > commit_message.txt
else
  echo "Update PR: Refresh upgrade parameters for $VERSION" > commit_message.txt
fi

# Create commit (allow empty for parameter updates)
if git diff --cached --quiet && git diff --quiet; then
  git commit --allow-empty -m "$(cat commit_message.txt)"
else
  git commit -m "$(cat commit_message.txt)"
fi

# Push changes
git push origin "$BRANCH_NAME"

# Create or update PR using gh CLI
EXISTING_PR=$(gh pr list --head "$BRANCH_NAME" --base "$TARGET_BRANCH" --json number --jq '.[0].number' 2>/dev/null || echo "")

if [ -n "$EXISTING_PR" ] && [ "$EXISTING_PR" != "null" ]; then
  echo "Updating existing PR #$EXISTING_PR"
  gh pr edit "$EXISTING_PR" --body-file pr_body.md
  echo "✅ Updated PR #$EXISTING_PR"
else
  echo "Creating new PR"
  gh pr create \
    --base "$TARGET_BRANCH" \
    --head "$BRANCH_NAME" \
    --title "🚀 Upgrade to Xion $RELEASE_TAG" \
    --body-file pr_body.md
  echo "✅ PR created successfully"
fi

# Clean up temporary file
rm -f commit_message.txt
