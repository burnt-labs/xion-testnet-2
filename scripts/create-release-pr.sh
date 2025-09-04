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

# Network name (set by workflow, defaults to xion-testnet-2)
NETWORK_NAME="${NETWORK_NAME:-xion-testnet-2}"

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

# Check if a proposal with same version and parameters already exists
EXISTING_PROPOSAL=""
PROPOSAL_FILE=""
NEXT_NUM=""

# Look for existing proposals with the same version
echo "Checking for existing proposals with version $VERSION..."
for file in proposals/*-upgrade-${VERSION}.json; do
    if [ -f "$file" ]; then
        echo "Found existing proposal: $file"
        # Check if the content matches our parameters
        if command -v jq >/dev/null 2>&1; then
            EXISTING_HEIGHT=$(jq -r '.messages[0].plan.height' "$file" 2>/dev/null)
            EXISTING_DEPOSIT=$(jq -r '.deposit' "$file" 2>/dev/null)
            EXISTING_EXPEDITED=$(jq -r '.expedited' "$file" 2>/dev/null)
            
            echo "  Existing: height=$EXISTING_HEIGHT, deposit=$EXISTING_DEPOSIT, expedited=$EXISTING_EXPEDITED"
            echo "  Current:  height=$HEIGHT, deposit=$DEPOSIT, expedited=$EXPEDITED"
            
            if [ "$EXISTING_HEIGHT" = "$HEIGHT" ] && 
               [ "$EXISTING_DEPOSIT" = "$DEPOSIT" ] && 
               [ "$EXISTING_EXPEDITED" = "$EXPEDITED" ]; then
                echo "✅ Found identical proposal: $file"
                echo "   Parameters match - will reuse existing proposal file"
                EXISTING_PROPOSAL="$file"
                PROPOSAL_FILE="$file"
                break
            else
                echo "   Parameters differ - will create new proposal"
            fi
        else
            echo "   jq not available - cannot compare content"
        fi
    fi
done

# If no matching proposal found, create a new one
if [ -z "$EXISTING_PROPOSAL" ]; then
    echo "No existing proposal found with matching parameters. Creating new proposal..."
    
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
    echo "Will create new proposal: $PROPOSAL_FILE"
else
    # Extract the proposal number from existing file for other uses
    NEXT_NUM=$(basename "$EXISTING_PROPOSAL" | cut -d'-' -f1)
    echo "Reusing existing proposal number: $NEXT_NUM"
fi
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
        "info": "https://raw.githubusercontent.com/burnt-labs/${NETWORK_NAME}/main/releases/${VERSION}.json",
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

# Check if release file needs to be created/updated
RELEASE_FILE="releases/${VERSION}.json"
SHOULD_UPDATE_RELEASE=true

if [ -f "$RELEASE_FILE" ] && command -v jq >/dev/null 2>&1; then
    echo "Checking existing release file: $RELEASE_FILE"
    
    # Check if checksums match what we would write
    EXISTING_DARWIN_AMD64=$(jq -r '.binaries."darwin/amd64"' "$RELEASE_FILE" 2>/dev/null | grep -o 'checksum=sha256:[^"]*' | cut -d: -f2)
    EXISTING_DARWIN_ARM64=$(jq -r '.binaries."darwin/arm64"' "$RELEASE_FILE" 2>/dev/null | grep -o 'checksum=sha256:[^"]*' | cut -d: -f2)
    EXISTING_LINUX_AMD64=$(jq -r '.binaries."linux/amd64"' "$RELEASE_FILE" 2>/dev/null | grep -o 'checksum=sha256:[^"]*' | cut -d: -f2)
    EXISTING_LINUX_ARM64=$(jq -r '.binaries."linux/arm64"' "$RELEASE_FILE" 2>/dev/null | grep -o 'checksum=sha256:[^"]*' | cut -d: -f2)
    
    if [ "$EXISTING_DARWIN_AMD64" = "$DARWIN_AMD64_CHECKSUM" ] &&
       [ "$EXISTING_DARWIN_ARM64" = "$DARWIN_ARM64_CHECKSUM" ] &&
       [ "$EXISTING_LINUX_AMD64" = "$LINUX_AMD64_CHECKSUM" ] &&
       [ "$EXISTING_LINUX_ARM64" = "$LINUX_ARM64_CHECKSUM" ]; then
        echo "✅ Release file checksums match - no update needed"
        SHOULD_UPDATE_RELEASE=false
    else
        echo "📝 Release file checksums differ - will update"
        echo "  Current checksums in file vs new checksums:"
        echo "    Darwin AMD64: $EXISTING_DARWIN_AMD64 vs $DARWIN_AMD64_CHECKSUM"
        echo "    Darwin ARM64: $EXISTING_DARWIN_ARM64 vs $DARWIN_ARM64_CHECKSUM"
        echo "    Linux AMD64: $EXISTING_LINUX_AMD64 vs $LINUX_AMD64_CHECKSUM"
        echo "    Linux ARM64: $EXISTING_LINUX_ARM64 vs $LINUX_ARM64_CHECKSUM"
    fi
fi

if [ "$SHOULD_UPDATE_RELEASE" = true ]; then
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
else
    echo "ℹ️  Release file unchanged: $RELEASE_FILE"
fi

# Check if release notes file needs to be created/updated
RELEASE_NOTES_FILE="release_notes/${VERSION}.md"
SHOULD_UPDATE_RELEASE_NOTES=true

if [ -f "$RELEASE_NOTES_FILE" ]; then
    echo "Release notes file already exists: $RELEASE_NOTES_FILE"
    
    # Check if the file is empty (for test runs)
    if [ ! -s "$RELEASE_NOTES_FILE" ]; then
        echo "📝 Release notes file is empty - will populate with skeleton template for testing"
        SHOULD_UPDATE_RELEASE_NOTES=true
    else
        # Check if we have a new AI-generated template that might be different
        if [ -f ".github/workflows/templates/release_notes_template.md" ]; then
            # Compare with AI template if available
            if cmp -s ".github/workflows/templates/release_notes_template.md" "$RELEASE_NOTES_FILE"; then
                echo "✅ Release notes match AI template - no update needed"
                SHOULD_UPDATE_RELEASE_NOTES=false
            else
                echo "📝 AI template differs from existing release notes - will update"
            fi
        else
            echo "ℹ️  No AI template available - keeping existing release notes"
            SHOULD_UPDATE_RELEASE_NOTES=false
        fi
    fi
fi

if [ "$SHOULD_UPDATE_RELEASE_NOTES" = true ]; then
    echo "Creating/updating release notes file: $RELEASE_NOTES_FILE"
    
    # Check if AI-generated template exists and has valid content
    if [ -f ".github/workflows/templates/release_notes_template.md" ] && [ -s ".github/workflows/templates/release_notes_template.md" ] && [ $(wc -c < ".github/workflows/templates/release_notes_template.md") -gt 50 ]; then
        # Additional check: ensure it's not just "null" or empty content
        TEMPLATE_CONTENT=$(cat ".github/workflows/templates/release_notes_template.md")
        if [ "$TEMPLATE_CONTENT" != "null" ] && [ -n "$TEMPLATE_CONTENT" ]; then
            echo "Using AI-generated release notes template"
            cp .github/workflows/templates/release_notes_template.md "$RELEASE_NOTES_FILE"
        else
            echo "Template file exists but contains invalid content, using fallback template"
            # Fall through to default template
        fi
    fi
    
    # Use default template if AI template is not available or invalid
    if [ ! -f "$RELEASE_NOTES_FILE" ] || [ ! -s "$RELEASE_NOTES_FILE" ]; then
        echo "Using default release notes skeleton template"
    cat > "$RELEASE_NOTES_FILE" << EOF
# Xion {{RELEASE_TAG}} Release Notes

## Overview

The Xion {{RELEASE_TAG}} series includes [--ADD-HERE-OVERVIEW-DESCRIPTION--]. This is the initial release with only {{RELEASE_TAG}} available.

## What's Changed

### {{RELEASE_TAG}} (Only Version)

#### WebAuthn & Authentication
- **[--ADD-HERE-WEBAUTHN-FEATURE--]**: [--ADD-HERE-DESCRIPTION--] by [@--ADD-HERE-USERNAME--](https://github.com/--ADD-HERE-USERNAME--) in [#--ADD-HERE-PR-NUMBER--](https://github.com/burnt-labs/xion/pull/--ADD-HERE-PR-NUMBER--)

#### CosmWasm & Module Updates
- **[--ADD-HERE-COSMWASM-UPDATE--]**: [--ADD-HERE-DESCRIPTION--] by [@--ADD-HERE-USERNAME--](https://github.com/--ADD-HERE-USERNAME--) in [#--ADD-HERE-PR-NUMBER--](https://github.com/burnt-labs/xion/pull/--ADD-HERE-PR-NUMBER--)

#### Protocol & Core Changes
- **[--ADD-HERE-PROTOCOL-CHANGE--]**: [--ADD-HERE-DESCRIPTION--] by [@--ADD-HERE-USERNAME--](https://github.com/--ADD-HERE-USERNAME--) in [#--ADD-HERE-PR-NUMBER--](https://github.com/burnt-labs/xion/pull/--ADD-HERE-PR-NUMBER--)

#### Bug Fixes & Improvements
- **[--ADD-HERE-BUG-FIX--]**: [--ADD-HERE-DESCRIPTION--] by [@--ADD-HERE-USERNAME--](https://github.com/--ADD-HERE-USERNAME--) in [#--ADD-HERE-PR-NUMBER--](https://github.com/burnt-labs/xion/pull/--ADD-HERE-PR-NUMBER--)
- **[--ADD-HERE-IMPROVEMENT--]**: [--ADD-HERE-DESCRIPTION--] by [@--ADD-HERE-USERNAME--](https://github.com/--ADD-HERE-USERNAME--) in [#--ADD-HERE-PR-NUMBER--](https://github.com/burnt-labs/xion/pull/--ADD-HERE-PR-NUMBER--)

#### Code Quality & Testing
- **[--ADD-HERE-TEST-UPDATE--]**: [--ADD-HERE-DESCRIPTION--] by [@--ADD-HERE-USERNAME--](https://github.com/--ADD-HERE-USERNAME--) in [#--ADD-HERE-PR-NUMBER--](https://github.com/burnt-labs/xion/pull/--ADD-HERE-PR-NUMBER--)
- **[--ADD-HERE-CODE-QUALITY--]**: [--ADD-HERE-DESCRIPTION--] by [@--ADD-HERE-USERNAME--](https://github.com/--ADD-HERE-USERNAME--) in [#--ADD-HERE-PR-NUMBER--](https://github.com/burnt-labs/xion/pull/--ADD-HERE-PR-NUMBER--)

## Upgrade Information

- **Upgrade Height**: [{{CALCULATED_HEIGHT}}](https://www.mintscan.io/xion-testnet/blocks/{{CALCULATED_HEIGHT}}) (testnet)
- **Proposal Number**: [{{CALCULATED_PROPOSAL_NUMBER}}](https://www.mintscan.io/xion-testnet/proposals/{{CALCULATED_PROPOSAL_NUMBER}})
- **Upgrade Name**: [{{VERSION}}](https://github.com/burnt-labs/{{NETWORK_NAME}}/blob/main/proposals/{{CALCULATED_PROPOSAL_NUMBER}}-upgrade-{{VERSION}}.json)

## Release Links

- **{{RELEASE_TAG}}**: [GitHub Release](https://github.com/burnt-labs/xion/releases/tag/{{RELEASE_TAG}})

## Contributors

Special thanks to the following contributors who made this release possible:

- [@--ADD-HERE-CONTRIBUTOR-1--](https://github.com/--ADD-HERE-CONTRIBUTOR-1--)
- [@--ADD-HERE-CONTRIBUTOR-2--](https://github.com/--ADD-HERE-CONTRIBUTOR-2--)
- [@--ADD-HERE-CONTRIBUTOR-3--](https://github.com/--ADD-HERE-CONTRIBUTOR-3--)

## Full Changelog

[{{PREVIOUS_VERSION}}...{{RELEASE_TAG}}](https://github.com/burnt-labs/xion/compare/{{PREVIOUS_VERSION}}...{{RELEASE_TAG}})

---

For more information about the upgrade process, please refer to the [upgrade proposal](../proposals/{{CALCULATED_PROPOSAL_NUMBER}}-upgrade-{{RELEASE_TAG}}.json).
EOF
    fi
else
    echo "ℹ️  Release notes unchanged: $RELEASE_NOTES_FILE"
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

echo ""
echo "=== SUMMARY ==="
if [ -n "$EXISTING_PROPOSAL" ]; then
    echo "✅ Reused existing proposal: $PROPOSAL_FILE"
else
    echo "📝 Created new proposal: $PROPOSAL_FILE"
fi

if [ "$SHOULD_UPDATE_RELEASE" = true ]; then
    echo "📝 Updated release file: $RELEASE_FILE"
else
    echo "✅ Release file unchanged: $RELEASE_FILE"
fi

if [ "$SHOULD_UPDATE_RELEASE_NOTES" = true ]; then
    echo "📝 Updated release notes: $RELEASE_NOTES_FILE"
else
    echo "✅ Release notes unchanged: $RELEASE_NOTES_FILE"
fi

echo ""
if [ -n "$RELEASE_TAG" ]; then
    echo "Version from argument: $VERSION"
else
    echo "Version automatically calculated: $VERSION (next after v$LATEST_RELEASE)"
fi
echo "Proposal number: $NEXT_NUM"
echo ""
# Check if real checksums were used
if [[ "$DARWIN_AMD64_CHECKSUM" != *"--ADD-HERE-YOUR-VALUE--"* ]]; then
    echo "✅ Real checksums automatically fetched from GitHub release"
else
    echo "📝 Placeholder checksums used (release not found or checksums unavailable)"
fi
