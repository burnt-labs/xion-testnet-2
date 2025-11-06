#!/bin/bash
# Generate release notes using Claude API
# Usage: ./scripts/generate-claude-notes.sh <prompt_file> <release_tag> <calculated_height> <previous_version> <api_key>

set -e

PROMPT_FILE="$1"
RELEASE_TAG="$2"
CALCULATED_HEIGHT="$3"
PREVIOUS_VERSION="$4"
CLAUDE_API_KEY="$5"

if [ -z "$PROMPT_FILE" ] || [ -z "$RELEASE_TAG" ] || [ -z "$CALCULATED_HEIGHT" ] || [ -z "$PREVIOUS_VERSION" ] || [ -z "$CLAUDE_API_KEY" ]; then
  echo "Error: Missing required arguments"
  echo "Usage: $0 <prompt_file> <release_tag> <calculated_height> <previous_version> <api_key>"
  exit 1
fi

# Read prompt from file
PROMPT=$(cat "$PROMPT_FILE")

# Replace placeholders with environment variables
PROMPT="${PROMPT//\{\{RELEASE_TAG\}\}/$RELEASE_TAG}"
PROMPT="${PROMPT//\{\{CALCULATED_HEIGHT\}\}/$CALCULATED_HEIGHT}"
PROMPT="${PROMPT//\{\{PREVIOUS_VERSION\}\}/$PREVIOUS_VERSION}"

echo "Loaded Claude API prompt from: $PROMPT_FILE"

# Combine prompt with comparison data
COMPARISON_JSON=$(cat comparison_data.json | jq -c .)
FULL_CONTENT="${PROMPT}\n\nGitHub Comparison Data:\n${COMPARISON_JSON}"

# Create API request JSON file to avoid "Argument list too long" error
cat > claude_request.json <<EOF
{
  "model": "claude-3-sonnet-20240229",
  "max_tokens": 4000,
  "messages": [
    {
      "role": "user",
      "content": $(echo "$FULL_CONTENT" | jq -Rs .)
    }
  ]
}
EOF

# Call Claude API using file input
CLAUDE_RESPONSE=$(curl -s -X POST "https://api.anthropic.com/v1/messages" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $CLAUDE_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  --data @claude_request.json)

# Check if API call was successful and extract content
API_ERROR=$(echo "$CLAUDE_RESPONSE" | jq -r '.error.message // empty')
if [ -n "$API_ERROR" ]; then
  echo "⚠️  Claude API error: $API_ERROR"
  echo "CLAUDE_API_FAILED=true"
  rm -f claude_request.json
  exit 1
else
  # Extract the response content and validate it
  RELEASE_NOTES_CONTENT=$(echo "$CLAUDE_RESPONSE" | jq -r '.content[0].text // empty')

  # Check if content is valid (not null, not empty, not just whitespace)
  if [ -n "$RELEASE_NOTES_CONTENT" ] && [ "$RELEASE_NOTES_CONTENT" != "null" ] && [ ${#RELEASE_NOTES_CONTENT} -gt 50 ]; then
    echo "✅ Claude API returned valid content (${#RELEASE_NOTES_CONTENT} characters)"
    echo "$RELEASE_NOTES_CONTENT" > generated_release_notes.md
    echo "CLAUDE_API_FAILED=false"
  else
    echo "⚠️  Claude API returned invalid/empty content: '$RELEASE_NOTES_CONTENT'"
    echo "CLAUDE_API_FAILED=true"
    rm -f claude_request.json
    exit 1
  fi
fi

# Clean up temporary file
rm -f claude_request.json
