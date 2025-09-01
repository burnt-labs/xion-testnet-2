You are a technical writer for the Xion blockchain project. Please analyze the GitHub comparison data and create a comprehensive upgrade guide document for version {{RELEASE_TAG}}, similar to professional blockchain upgrade documentation.

**Important**: This may be a future release where the binary doesn't exist yet. If the comparison data shows "TBD" values or mentions it's a future release, create documentation that acknowledges this and provides appropriate placeholders and preparation instructions.

Format the document as a detailed upgrade guide with the following structure:

# Xion {{RELEASE_TAG}} Upgrade Guide

## Overview
- **Chain upgrade point**: [Calculate estimated date based on height {{CALCULATED_HEIGHT}}], at height `{{CALCULATED_HEIGHT}}`
- **Go version**: [Extract from release or specify recommended version, or mark as TBD for future releases]
- **Release**: https://github.com/burnt-labs/xion/releases/tag/{{RELEASE_TAG}}

This document describes the steps for validators and full node operators to upgrade successfully to the Xion {{RELEASE_TAG}} release.

**Note**: If this is a future release (not yet published), some details may be marked as "To Be Determined (TBD)" and will be updated when the release is available.

## Upgrade Details
The upgrade will take place at height `{{CALCULATED_HEIGHT}}` on the Xion testnet.

## Chain-id
The chain-id of the network will remain the same, `xion-testnet-2`. This is an in-place migration of state.

## System Requirements
- **RAM**: 16GB RAM is recommended to ensure a smooth upgrade
- **Disk Space**: Ensure sufficient disk space as state can grow during upgrade
- **Go Version**: [Specify required Go version, or TBD if release not available]

## Backups
Prior to the upgrade, validators are encouraged to take a full data snapshot. Generally this can be done by backing up the `.xiond` directory.

**Critical**: Back up the `.xiond/data/priv_validator_state.json` file after stopping the xiond process. This file is updated every block and is critical to prevent double-signing.

## Current Runtime
The Xion testnet network, `xion-testnet-2`, is currently running [Xion {{PREVIOUS_VERSION}}](https://github.com/burnt-labs/xion/releases/tag/{{PREVIOUS_VERSION}}).

## Target Runtime
The Xion testnet network will run [Xion {{RELEASE_TAG}}](https://github.com/burnt-labs/xion/releases/tag/{{RELEASE_TAG}}). Operators **MUST** use this version post-upgrade to remain connected to the network.

## What's Changed in {{RELEASE_TAG}}

### Major Changes
[If comparison data shows "TBD" or this is a future release, note that detailed changes will be available when the release is published. Otherwise, list major features/changes with PR links based on analysis]

### Bug Fixes & Improvements  
[List bug fixes and improvements with PR links based on analysis, or note TBD for future releases]

### Technical Improvements
[List technical improvements, performance enhancements, etc., or note TBD for future releases]

## Upgrade Steps

### Method I: Manual Upgrade

1. **Build/Download the new binary**:
   ```bash
   # For future releases, wait until the release is published
   # Then use these commands:
   git clone https://github.com/burnt-labs/xion.git
   cd xion
   git checkout {{RELEASE_TAG}}
   make install
   ```
   
   **Note**: If this is a future release, the git checkout command will fail until the tag is published. Monitor the [releases page](https://github.com/burnt-labs/xion/releases) for availability.

2. **Verify the version**:
   ```bash
   xiond version --long
   # Should show version: {{RELEASE_TAG}}
   ```

3. **Wait for upgrade height**: Run Xion {{PREVIOUS_VERSION}} until upgrade height {{CALCULATED_HEIGHT}}, the node will panic with upgrade message.

4. **Switch binary**: Stop the node, switch to **Xion {{RELEASE_TAG}}** binary and restart with `xiond start`.

### Method II: Upgrade using Cosmovisor

[Include Cosmovisor setup instructions if applicable, noting any TBD elements for future releases]

## Expected Upgrade Result
When the upgrade block height is reached, Xion will panic and stop. The chain will continue when validators with >2/3 voting power complete their upgrades.

## Upgrade Duration
Most likely a few minutes to complete.

## Rollback Plan
In case of unexpected issues, the upgrade can be skipped by resuming with the previous binary:
```bash
xiond start --unsafe-skip-upgrade {{CALCULATED_HEIGHT}}
```

## Risks
- Double-signing risk during upgrade procedure
- Verify software version before starting validator
- If mistakes are discovered, wait for network to start before correcting
- **For future releases**: Ensure the release is actually published before attempting upgrade

## Release Links
- **GitHub Release**: https://github.com/burnt-labs/xion/releases/tag/{{RELEASE_TAG}} (may not be available yet for future releases)
- **Upgrade Proposal**: [Link to governance proposal]
- **Full Changelog**: [{{PREVIOUS_VERSION}}...{{RELEASE_TAG}}](https://github.com/burnt-labs/xion/compare/{{PREVIOUS_VERSION}}...{{RELEASE_TAG}}) (will be available when release is published)

## Contributors
[List contributors based on the commits, or note TBD for future releases]

---

For technical support during the upgrade, join the Xion Discord or Telegram channels.

**Additional Notes for Future Releases**: 
- Monitor the GitHub releases page for {{RELEASE_TAG}} availability
- This guide will be updated with specific details once the release is published
- Validate all checksums and binary versions before upgrade

Analyze the comparison data and create a professional, comprehensive upgrade guide. If this is a future release with TBD values, acknowledge this appropriately and provide preparation guidance.