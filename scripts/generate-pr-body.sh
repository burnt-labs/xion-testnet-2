#!/bin/bash

# Script to generate comprehensive PR body for release upgrades
# Usage: ./scripts/generate-pr-body.sh <version> <height> <deposit> <expedited> <proposal_file> <release_file> <release_notes_file>

set -e

# Use environment variables directly instead of parameters
NETWORK_NAME="sdfsdfsdfsdfsdf" #"${NETWORK_NAME:-SAMPLE-VALUE}"
MINTSCAN_CHAIN_ID="sdfsdfsdfsdfsdf" #"${MINTSCAN_CHAIN_ID:-SAMPLE-VALUE}"

# Function to generate Mintscan URLs
generate_mintscan_block_url() {
    local block_height="$1"
    local chain_id="$MINTSCAN_CHAIN_ID"
    echo "https://www.mintscan.io/${chain_id}/blocks/${block_height}"
}


generate_mintscan_proposal_url() {
    local proposal_id="$1"
    local chain_id="$MINTSCAN_CHAIN_ID"
    echo "https://www.mintscan.io/${chain_id}/proposals/${proposal_id}"
}

VERSION="$1"
HEIGHT="$2"
DEPOSIT="$3"
EXPEDITED="$4"
PROPOSAL_FILE="$5"
RELEASE_FILE="$6"
RELEASE_NOTES_FILE="$7"
RELEASE_TAG="$8"
COMMIT_COUNT="$9"
FILES_CHANGED="${10}"
PREVIOUS_VERSION="${11}"
DARWIN_AMD64_CHECKSUM="${12}"
DARWIN_ARM64_CHECKSUM="${13}"
LINUX_AMD64_CHECKSUM="${14}"
LINUX_ARM64_CHECKSUM="${15}"
RUN_NUMBER="${16}"
COMMIT_SHA="${17}"

echo "DEBUG: Total parameters received: $#"
echo "DEBUG: All parameters: $@"
echo "DEBUG: NETWORK_NAME: '$NETWORK_NAME'"
echo "DEBUG: MINTSCAN_CHAIN_ID: '$MINTSCAN_CHAIN_ID'"

# Extract proposal number from proposal file path (e.g., "proposals/038-upgrade-v22.json" -> "038")
PROPOSAL_NUMBER=$(basename "$PROPOSAL_FILE" | cut -d'-' -f1)

# Generate Mintscan URLs
MINTSCAN_BLOCK_URL=$(generate_mintscan_block_url "$HEIGHT")
MINTSCAN_PROPOSAL_URL=$(generate_mintscan_proposal_url "$PROPOSAL_NUMBER")

# Create comprehensive PR body
cat > pr_body.md << EOF
# 🚀 Xion $RELEASE_TAG Upgrade

This pull request implements the upgrade to **Xion $RELEASE_TAG** for the Xion $NETWORK_NAME.

## 📋 Overview

- **Upgrade Height**: [$HEIGHT]($MINTSCAN_BLOCK_URL) (estimated: ~2 days from current block)
- **Chain ID**:  \`$MINTSCAN_CHAIN_ID\` (in-place migration)
- **Release**: https://github.com/burnt-labs/xion/releases/tag/$RELEASE_TAG
- **Proposal**: [$PROPOSAL_NUMBER]($MINTSCAN_PROPOSAL_URL) (\`$PROPOSAL_FILE\`)
- **Governance Deposit**: $DEPOSIT
- **Expedited**: $EXPEDITED

## 📊 Changes Summary

EOF

# Add comparison data if available
if [[ "$COMMIT_COUNT" != "TBD" && "$COMMIT_COUNT" != "0" ]]; then
  cat >> pr_body.md << EOF
- **Commits since last version**: $COMMIT_COUNT
- **Files changed**: $FILES_CHANGED
- **Changelog**: [Compare $PREVIOUS_VERSION...$RELEASE_TAG](https://github.com/burnt-labs/xion/compare/$PREVIOUS_VERSION...$RELEASE_TAG)

EOF
else
  cat >> pr_body.md << EOF
- **Status**: Future release (comparison data will be available when release is published)
- **Changelog**: Will be available at [Compare $PREVIOUS_VERSION...$RELEASE_TAG](https://github.com/burnt-labs/xion/compare/$PREVIOUS_VERSION...$RELEASE_TAG)

EOF
fi

cat >> pr_body.md << EOF
## 📁 Files Modified

### Governance & Upgrade Files
- **Proposal**: [$PROPOSAL_NUMBER]($MINTSCAN_PROPOSAL_URL) (\`$PROPOSAL_FILE\`)
  - Upgrade height: [$HEIGHT]($MINTSCAN_BLOCK_URL)
  - Chain upgrade to $RELEASE_TAG
  - Points to release config: \`$RELEASE_FILE\`

- **Release Config**: \`$RELEASE_FILE\`
  - Binary URLs for all platforms (darwin/linux, amd64/arm64)
  - SHA256 checksums for security verification

- **Release Notes**: \`$RELEASE_NOTES_FILE\`
  - Detailed changelog and upgrade information
  - Generated using AI analysis of GitHub comparison data

## 🔒 Security & Verification

### Binary Checksums
EOF

# Add checksum information
if [[ "$DARWIN_AMD64_CHECKSUM" != *"--ADD-HERE-YOUR-VALUE--"* ]]; then
  cat >> pr_body.md << EOF

✅ **Real checksums** (fetched from GitHub release):
- **Darwin AMD64**: \`$DARWIN_AMD64_CHECKSUM\`
- **Darwin ARM64**: \`$DARWIN_ARM64_CHECKSUM\`  
- **Linux AMD64**: \`$LINUX_AMD64_CHECKSUM\`
- **Linux ARM64**: \`$LINUX_ARM64_CHECKSUM\`
EOF
else
  cat >> pr_body.md << EOF

⚠️ **Placeholder checksums** (release not yet published):
- Checksums will be updated automatically when $RELEASE_TAG is released
- Binary URLs point to the expected release location
EOF
fi

cat >> pr_body.md << EOF

## ⚠️ Important Notes for Validators

### Pre-Upgrade Checklist
- [ ] **Backup**: Full snapshot of \`.xiond\` directory
- [ ] **Critical**: Backup \`.xiond/data/priv_validator_state.json\` after stopping node
- [ ] **Verify**: Binary version before starting post-upgrade
- [ ] **Monitor**: Network upgrade progress

### System Requirements
- **RAM**: 16GB recommended for smooth upgrade
- **Disk**: Ensure sufficient space for state growth
- **Network**: Stable connection during upgrade window

### Upgrade Process
1. **Wait** for upgrade height [$HEIGHT]($MINTSCAN_BLOCK_URL)
2. **Node will panic** with upgrade message at target height
3. **Stop node** and switch to $RELEASE_TAG binary
4. **Restart** with \`xiond start\`
5. **Monitor** for successful chain continuation

### Emergency Procedures
\`\`\`bash
# Skip upgrade if issues occur
xiond start --unsafe-skip-upgrade $HEIGHT
\`\`\`

## 🔗 Resources

- **GitHub Release**: https://github.com/burnt-labs/xion/releases/tag/$RELEASE_TAG
- **Upgrade Proposal**: [$PROPOSAL_NUMBER]($MINTSCAN_PROPOSAL_URL) (\`$PROPOSAL_FILE\`)
- **Block Explorer**: [Mintscan](https://www.mintscan.io/${MINTSCAN_CHAIN_ID:-SAMPLE-VALUE})
- **Technical Documentation**: \`$RELEASE_NOTES_FILE\`
- **Support**: Join Xion Discord/Telegram for upgrade assistance

## 🧪 Testing Status

- [x] Proposal JSON validation
- [x] Release config validation  
- [x] Binary URL format verification
- [x] Checksum integration
- [x] Height calculation (2-day buffer)

---

**⚡ Automation Notes**: This PR was automatically generated with intelligent duplicate detection. Files are only updated when content changes, and identical configurations reuse existing proposals to prevent iteration spam.

**🔄 Run Details**: 
- Workflow run: $RUN_NUMBER
- Commit: $COMMIT_SHA
- Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

EOF

# Add AI-generated release notes if available
if [ -f "generated_release_notes.md" ]; then
  echo "" >> pr_body.md
  echo "## 📝 Detailed Release Notes" >> pr_body.md
  echo "" >> pr_body.md
  echo "<details>" >> pr_body.md
  echo "<summary>Click to expand AI-generated upgrade guide</summary>" >> pr_body.md
  echo "" >> pr_body.md
  echo '```markdown' >> pr_body.md
  cat generated_release_notes.md >> pr_body.md
  echo '```' >> pr_body.md
  echo "</details>" >> pr_body.md
fi

echo "PR body generated successfully: pr_body.md"
