#!/bin/bash

# Script to create upgrade proposal files
# Usage: ./scripts/create-release-pr.sh <height> [deposit] [expedited] [release_tag]
# Example: ./scripts/create-release-pr.sh 7500000 1000000000uxion false v22.0.0
# Note: If no release_tag is provided, version is automatically determined from the latest release

set -e

# Environment variables for checksums (set by workflow)
# Use real checksums if available, otherwise fallback to placeholders
DARWIN_AMD64_CHECKSUM="${DARWIN_AMD64_CHECKSUM:-${PLACEHOLDER_CHECKSUM_DARWIN_AMD64:---ADD-HERE-YOUR-VALUE--}}"
DARWIN_ARM64_CHECKSUM="${DARWIN_ARM64_CHECKSUM:-${PLACEHOLDER_CHECKSUM_DARWIN_ARM64:---ADD-HERE-YOUR-VALUE--}}"
LINUX_AMD64_CHECKSUM="${LINUX_AMD64_CHECKSUM:-${PLACEHOLDER_CHECKSUM_LINUX_AMD64:---ADD-HERE-YOUR-VALUE--}}"
LINUX_ARM64_CHECKSUM="${LINUX_ARM64_CHECKSUM:-${PLACEHOLDER_CHECKSUM_LINUX_ARM64:---ADD-HERE-YOUR-VALUE--}}"

# Validate checksums are not empty (fallback to placeholder if empty)
DARWIN_AMD64_CHECKSUM="${DARWIN_AMD64_CHECKSUM:-"--ADD-HERE-YOUR-VALUE--"}"
DARWIN_ARM64_CHECKSUM="${DARWIN_ARM64_CHECKSUM:-"--ADD-HERE-YOUR-VALUE--"}"
LINUX_AMD64_CHECKSUM="${LINUX_AMD64_CHECKSUM:-"--ADD-HERE-YOUR-VALUE--"}"
LINUX_ARM64_CHECKSUM="${LINUX_ARM64_CHECKSUM:-"--ADD-HERE-YOUR-VALUE--"}"

echo "Debug - Checksums being used:"
echo "  DARWIN_AMD64_CHECKSUM: '$DARWIN_AMD64_CHECKSUM'"
echo "  DARWIN_ARM64_CHECKSUM: '$DARWIN_ARM64_CHECKSUM'"
echo "  LINUX_AMD64_CHECKSUM: '$LINUX_AMD64_CHECKSUM'"
echo "  LINUX_ARM64_CHECKSUM: '$LINUX_ARM64_CHECKSUM'"

# Check if required arguments are provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <height> [deposit] [expedited] [release_tag]"
    echo "Example: $0 7500000 1000000000uxion false v22.0.0"
    echo "Note: If no release_tag is provided, version is automatically determined from the latest release"
    exit 1
fi

HEIGHT="$1"
DEPOSIT="${2:-1000000000uxion}"
EXPEDITED="${3:-false}"
RELEASE_TAG="$4"

echo "Debug - Script arguments:"
echo "  HEIGHT: '$HEIGHT'"
echo "  DEPOSIT: '$DEPOSIT'"
echo "  EXPEDITED: '$EXPEDITED'"
echo "  RELEASE_TAG: '$RELEASE_TAG'"

# Ensure we're in the right directory
cd "$(dirname "$0")/.."

# Determine version from argument or calculate from latest release
if [ -n "$RELEASE_TAG" ]; then
    # Validate RELEASE_TAG format (should be like v22.0.0)
    if [[ ! "$RELEASE_TAG" =~ ^v[0-9]+\.0\.0$ ]]; then
        echo "Error: RELEASE_TAG must be in format vX.0.0 (e.g., v22.0.0)"
        echo "Provided: '$RELEASE_TAG'"
        exit 1
    fi
    
    # Use RELEASE_TAG from argument (full version for content)
    VERSION_FULL="$RELEASE_TAG"
    VERSION_NUM=$(echo "$VERSION_FULL" | sed 's/v\([0-9]*\)\.0\.0/\1/')
    # Create short version for filenames (v22 instead of v22.0.0)
    VERSION="v${VERSION_NUM}"
    echo "Using specified version: $VERSION_FULL (files will use: $VERSION)"
else
    # Find the latest release version (auto-calculate mode)
    LATEST_RELEASE=$(ls releases/ | grep -E '^v[0-9]+\.json$' | sed 's/v\([0-9]*\)\.json/\1/' | sort -n | tail -1)
    if [ -z "$LATEST_RELEASE" ]; then
        echo "No release files found in releases/ directory"
        exit 1
    fi
    
    # Calculate next version
    NEXT_VERSION_NUM=$((LATEST_RELEASE + 1))
    VERSION="v${NEXT_VERSION_NUM}"
    VERSION_NUM="$NEXT_VERSION_NUM"
    VERSION_FULL="${VERSION}.0.0"
    echo "Calculated next version: $VERSION_FULL (files will use: $VERSION)"
fi

echo "Version to create: $VERSION"

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

# Create/update the proposal JSON
echo "Creating/updating proposal file: $PROPOSAL_FILE"
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

# Create/update release file
RELEASE_FILE="releases/${VERSION}.json"
echo "Creating/updating release file: $RELEASE_FILE"
cat > "$RELEASE_FILE" << EOF
{
    "binaries": {
        "darwin/amd64": "https://github.com/burnt-labs/xion/releases/download/${VERSION_FULL}/xiond_${VERSION_NUM}.0.0_darwin_amd64.tar.gz?checksum=sha256:${DARWIN_AMD64_CHECKSUM}",
        "darwin/arm64": "https://github.com/burnt-labs/xion/releases/download/${VERSION_FULL}/xiond_${VERSION_NUM}.0.0_darwin_arm64.tar.gz?checksum=sha256:${DARWIN_ARM64_CHECKSUM}",
        "linux/amd64": "https://github.com/burnt-labs/xion/releases/download/${VERSION_FULL}/xiond_${VERSION_NUM}.0.0_linux_amd64.tar.gz?checksum=sha256:${LINUX_AMD64_CHECKSUM}",
        "linux/arm64": "https://github.com/burnt-labs/xion/releases/download/${VERSION_FULL}/xiond_${VERSION_NUM}.0.0_linux_arm64.tar.gz?checksum=sha256:${LINUX_ARM64_CHECKSUM}"
    }
}
EOF

# Create/update release notes markdown file
RELEASE_NOTES_FILE="release_notes/${VERSION}.md"
echo "Creating/updating release notes file: $RELEASE_NOTES_FILE"

# Check if AI-generated template exists
if [ -f "release_notes_template.md" ]; then
    echo "Using AI-generated release notes template"
    cp release_notes_template.md "$RELEASE_NOTES_FILE"
else
    echo "Using default release notes template"
    cat > "$RELEASE_NOTES_FILE" << EOF
# Xion ${VERSION_FULL} Release Notes

## Overview

Xion ${VERSION_FULL} includes [--ADD-HERE-YOUR-DESCRIPTION--]. This is the initial release with only ${VERSION_FULL} available.

## What's Changed

### ${VERSION_FULL} (Only Version)

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

- **${VERSION_FULL}**: [GitHub Release](https://github.com/burnt-labs/xion/releases/tag/${VERSION_FULL})

## Contributors

Special thanks to the following contributors who made this release possible:

- [@--ADD-HERE-YOUR-VALUE--](https://github.com/--ADD-HERE-YOUR-VALUE--)
- [@--ADD-HERE-YOUR-VALUE--](https://github.com/--ADD-HERE-YOUR-VALUE--)

## Full Changelog

[Previous version...${VERSION_FULL}](https://github.com/burnt-labs/xion/compare/--ADD-HERE-PREVIOUS-VERSION--...${VERSION_FULL})

---

For more information about the upgrade process, please refer to the [upgrade proposal](../proposals/${NEXT_NUM}-upgrade-${VERSION}.json).
EOF
fi

# Format JSON files if jq is available
if command -v jq >/dev/null 2>&1; then
    echo "Formatting JSON files..."
    
    # Validate and format proposal file
    echo "Validating proposal file: $PROPOSAL_FILE"
    if jq . "$PROPOSAL_FILE" > /dev/null 2>&1; then
        echo "✅ Proposal file is valid JSON"
        jq . "$PROPOSAL_FILE" > temp.json && mv temp.json "$PROPOSAL_FILE"
    else
        echo "❌ Proposal file has invalid JSON, showing content:"
        cat "$PROPOSAL_FILE"
        echo "--- End of proposal file ---"
    fi
    
    # Validate and format release file
    if [ -f "$RELEASE_FILE" ]; then
        echo "Validating release file: $RELEASE_FILE"
        if jq . "$RELEASE_FILE" > /dev/null 2>&1; then
            echo "✅ Release file is valid JSON"
            jq . "$RELEASE_FILE" > temp.json && mv temp.json "$RELEASE_FILE"
        else
            echo "❌ Release file has invalid JSON, showing content:"
            cat "$RELEASE_FILE"
            echo "--- End of release file ---"
        fi
    fi
else
    echo "jq not found, skipping JSON formatting"
fi

echo "Successfully created/updated:"
echo "  - $PROPOSAL_FILE"
[ -f "$RELEASE_FILE" ] && echo "  - $RELEASE_FILE"
[ -f "$RELEASE_NOTES_FILE" ] && echo "  - $RELEASE_NOTES_FILE"
echo ""
if [ -n "$RELEASE_TAG" ]; then
    echo "Version from argument: $VERSION"
else
    echo "Version automatically calculated: $VERSION (next after v$LATEST_RELEASE)"
fi
echo ""
# Check if real checksums were used
if [[ "$DARWIN_AMD64_CHECKSUM" != *"--ADD-HERE-YOUR-VALUE--"* ]]; then
    echo "✅ Real checksums automatically fetched from GitHub release"
else
    echo "📝 Placeholder checksums used (release not found or checksums unavailable)"
fi
