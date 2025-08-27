#!/bin/bash

# Script to create upgrade proposal files
# Usage: ./scripts/create-proposal.sh <height> [deposit] [expedited]
# Example: ./scripts/create-proposal.sh 7500000 1000000000uxion false
# The version is automatically determined from the latest release

set -e

# Environment variables for checksums (set by workflow)
# Use real checksums if available, otherwise fallback to placeholders
DARWIN_AMD64_CHECKSUM="${DARWIN_AMD64_CHECKSUM:-${PLACEHOLDER_CHECKSUM_DARWIN_AMD64:---ADD-HERE-YOUR-VALUE--}}"
DARWIN_ARM64_CHECKSUM="${DARWIN_ARM64_CHECKSUM:-${PLACEHOLDER_CHECKSUM_DARWIN_ARM64:---ADD-HERE-YOUR-VALUE--}}"
LINUX_AMD64_CHECKSUM="${LINUX_AMD64_CHECKSUM:-${PLACEHOLDER_CHECKSUM_LINUX_AMD64:---ADD-HERE-YOUR-VALUE--}}"
LINUX_ARM64_CHECKSUM="${LINUX_ARM64_CHECKSUM:-${PLACEHOLDER_CHECKSUM_LINUX_ARM64:---ADD-HERE-YOUR-VALUE--}}"

# Check if required arguments are provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <height> [deposit] [expedited]"
    echo "Example: $0 7500000 1000000000uxion false"
    echo "Note: Version is automatically determined from the latest release"
    exit 1
fi

HEIGHT="$1"
DEPOSIT="${2:-1000000000uxion}"
EXPEDITED="${3:-false}"

# Ensure we're in the right directory
cd "$(dirname "$0")/.."

# Find the latest release version
LATEST_RELEASE=$(ls releases/ | grep -E '^v[0-9]+\.json$' | sed 's/v\([0-9]*\)\.json/\1/' | sort -n | tail -1)
if [ -z "$LATEST_RELEASE" ]; then
    echo "No release files found in releases/ directory"
    exit 1
fi

# Calculate next version
NEXT_VERSION_NUM=$((LATEST_RELEASE + 1))
VERSION="v${NEXT_VERSION_NUM}"
VERSION_NUM="$NEXT_VERSION_NUM"

echo "Latest release: v${LATEST_RELEASE}"
echo "Next version: $VERSION"

# Find the next proposal number by checking existing files
LATEST_PROPOSAL=$(ls proposals/ | grep -E '^[0-9]{3}-upgrade-v[0-9]+\.json$' | sort -V | tail -1)
if [ -z "$LATEST_PROPOSAL" ]; then
    NEXT_NUM="001"
else
    CURRENT_NUM=$(echo $LATEST_PROPOSAL | cut -d'-' -f1)
    NEXT_NUM=$(printf "%03d" $((10#$CURRENT_NUM + 1)))
fi

# Skip if number is already taken (handle gaps in numbering)
while [ -f "proposals/${NEXT_NUM}-upgrade-${VERSION}.json" ]; do
    NEXT_NUM=$(printf "%03d" $((10#$NEXT_NUM + 1)))
done

PROPOSAL_FILE="proposals/${NEXT_NUM}-upgrade-${VERSION}.json"
AUTHORITY="xion10d07y265gmmuvt4z0w9aw880jnsr700jctf8qc"

echo "Creating proposal file: $PROPOSAL_FILE"

# Create the proposal JSON
cat > "$PROPOSAL_FILE" << EOF
{
  "messages": [
    {
      "@type": "/cosmos.upgrade.v1beta1.MsgSoftwareUpgrade",
      "authority": "$AUTHORITY",
      "plan": {
        "name": "$VERSION",
        "height": "$HEIGHT",
        "info": "https://raw.githubusercontent.com/burnt-labs/xion-testnet-2/main/releases/${VERSION}.json",
        "upgraded_client_state": null
      }
    }
  ],
  "title": "Software Upgrade $VERSION",
  "summary": "Software Upgrade $VERSION",
  "deposit": "$DEPOSIT",
  "expedited": $EXPEDITED
}
EOF

# Create release file placeholder if it doesn't exist
RELEASE_FILE="releases/${VERSION}.json"
if [ ! -f "$RELEASE_FILE" ]; then
    echo "Creating release file: $RELEASE_FILE"
    cat > "$RELEASE_FILE" << EOF
{
    "binaries": {
        "darwin/amd64": "https://github.com/burnt-labs/xion/releases/download/${VERSION}.0.0/xiond_${VERSION_NUM}.0.0_darwin_amd64.tar.gz?checksum=sha256:${DARWIN_AMD64_CHECKSUM}",
        "darwin/arm64": "https://github.com/burnt-labs/xion/releases/download/${VERSION}.0.0/xiond_${VERSION_NUM}.0.0_darwin_arm64.tar.gz?checksum=sha256:${DARWIN_ARM64_CHECKSUM}",
        "linux/amd64": "https://github.com/burnt-labs/xion/releases/download/${VERSION}.0.0/xiond_${VERSION_NUM}.0.0_linux_amd64.tar.gz?checksum=sha256:${LINUX_AMD64_CHECKSUM}",
        "linux/arm64": "https://github.com/burnt-labs/xion/releases/download/${VERSION}.0.0/xiond_${VERSION_NUM}.0.0_linux_arm64.tar.gz?checksum=sha256:${LINUX_ARM64_CHECKSUM}"
    }
}
EOF
else
    echo "Release file already exists: $RELEASE_FILE"
fi

# Create release notes markdown file if it doesn't exist
RELEASE_NOTES_FILE="release_notes/${VERSION}.md"
if [ ! -f "$RELEASE_NOTES_FILE" ]; then
    echo "Creating release notes file: $RELEASE_NOTES_FILE"
    
    # Check if AI-generated template exists
    if [ -f "release_notes_template.md" ]; then
        echo "Using AI-generated release notes template"
        cp release_notes_template.md "$RELEASE_NOTES_FILE"
    else
        echo "Using default release notes template"
        cat > "$RELEASE_NOTES_FILE" << EOF
# Xion ${VERSION} Release Notes

## Overview

Xion ${VERSION}.0.0 includes [--ADD-HERE-YOUR-DESCRIPTION--]. This is the initial release with only ${VERSION}.0.0 available.

## What's Changed

### ${VERSION}.0.0 (Only Version)

#### Major Changes

- **[Feature Name]**: [Description of major change] by [@username](https://github.com/username) in [#PR](https://github.com/burnt-labs/xion/pull/PR)
- **[Feature Name]**: [Description of major change] by [@username](https://github.com/username) in [#PR](https://github.com/burnt-labs/xion/pull/PR)

#### Bug Fixes & Improvements

- **[Fix Name]**: [Description of fix] by [@username](https://github.com/username) in [#PR](https://github.com/burnt-labs/xion/pull/PR)
- **[Improvement Name]**: [Description of improvement] by [@username](https://github.com/username) in [#PR](https://github.com/burnt-labs/xion/pull/PR)

#### Testing & Code Quality

- **[Test Name]**: [Description of test improvements] by [@username](https://github.com/username) in [#PR](https://github.com/burnt-labs/xion/pull/PR)

## Upgrade Information

- **Upgrade Height**: $HEIGHT (testnet)
- **Proposal Number**: $NEXT_NUM

## Release Links

- **${VERSION}.0.0**: [GitHub Release](https://github.com/burnt-labs/xion/releases/tag/${VERSION}.0.0)

## Contributors

Special thanks to the following contributors who made this release possible:

- [@--ADD-HERE-YOUR-VALUE--](https://github.com/--ADD-HERE-YOUR-VALUE--)
- [@--ADD-HERE-YOUR-VALUE--](https://github.com/--ADD-HERE-YOUR-VALUE--)

## Full Changelog

[Previous version...${VERSION}.0.0](https://github.com/burnt-labs/xion/compare/--ADD-HERE-PREVIOUS-VERSION--...${VERSION}.0.0)

---

For more information about the upgrade process, please refer to the [upgrade proposal](../proposals/${NEXT_NUM}-upgrade-${VERSION}.json).
EOF
    fi
else
    echo "Release notes file already exists: $RELEASE_NOTES_FILE"
fi

# Format JSON files if jq is available
if command -v jq >/dev/null 2>&1; then
    echo "Formatting JSON files..."
    jq . "$PROPOSAL_FILE" > temp.json && mv temp.json "$PROPOSAL_FILE"
    if [ -f "$RELEASE_FILE" ]; then
        jq . "$RELEASE_FILE" > temp.json && mv temp.json "$RELEASE_FILE"
    fi
else
    echo "jq not found, skipping JSON formatting"
fi

echo "Successfully created:"
echo "  - $PROPOSAL_FILE"
[ -f "$RELEASE_FILE" ] && echo "  - $RELEASE_FILE"
[ -f "$RELEASE_NOTES_FILE" ] && echo "  - $RELEASE_NOTES_FILE"
echo ""
echo "Version automatically determined: $VERSION (next after v$LATEST_RELEASE)"
echo ""
# Check if real checksums were used
if [[ "$DARWIN_AMD64_CHECKSUM" != *"--ADD-HERE-YOUR-VALUE--"* ]]; then
    echo "✅ Real checksums automatically fetched from GitHub release"
else
    echo "📝 Placeholder checksums used (release not found or checksums unavailable)"
fi
echo ""
echo "Next steps:"
if [[ "$DARWIN_AMD64_CHECKSUM" == *"--ADD-HERE-YOUR-VALUE--"* ]]; then
    echo "1. Update the checksums in $RELEASE_FILE with actual release binary checksums"
fi
echo "2. Review the proposal details"
echo "3. Commit and push the changes"
echo "4. Submit the proposal on-chain when ready"
