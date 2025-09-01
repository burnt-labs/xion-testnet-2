# Xion {{RELEASE_TAG}} Upgrade Guide

## Overview
- **Chain upgrade point**: TBD, at height `{{CALCULATED_HEIGHT}}`
- **Go version**: [To be determined]
- **Release**: https://github.com/burnt-labs/xion/releases/tag/{{RELEASE_TAG}}

This document describes the steps for validators and full node operators to upgrade successfully to the Xion {{RELEASE_TAG}} release.

**Note**: This may be documentation for a future release. Some details will be updated when the release is published.

## Upgrade Details
The upgrade will take place at height `{{CALCULATED_HEIGHT}}` on the Xion testnet.

## Chain-id
The chain-id of the network will remain the same, `xion-testnet-2`. This is an in-place migration of state.

## System Requirements
- **RAM**: 16GB RAM is recommended to ensure a smooth upgrade
- **Disk Space**: Ensure sufficient disk space as state can grow during upgrade
- **Go Version**: [To be determined based on release]

## Backups
Prior to the upgrade, validators are encouraged to take a full data snapshot. Generally this can be done by backing up the `.xiond` directory.

**Critical**: Back up the `.xiond/data/priv_validator_state.json` file after stopping the xiond process.

## Current Runtime
The Xion testnet network, `xion-testnet-2`, is currently running [Xion {{PREVIOUS_VERSION}}](https://github.com/burnt-labs/xion/releases/tag/{{PREVIOUS_VERSION}}).

## Target Runtime
The Xion testnet network will run [Xion {{RELEASE_TAG}}](https://github.com/burnt-labs/xion/releases/tag/{{RELEASE_TAG}}).

## What's Changed in {{RELEASE_TAG}}

### Major Changes
- [Changes will be filled by AI generation or manual review]

### Bug Fixes & Improvements
- [To be filled based on release analysis]

## Upgrade Steps

### Method I: Manual Upgrade

1. **Build the new binary**:
   ```bash
   # For future releases, wait until the release is published
   # Then use these commands:
   git clone https://github.com/burnt-labs/xion.git
   cd xion
   git checkout {{RELEASE_TAG}}
   make install
   ```
   
   **Note**: If this is a future release, the git checkout command will fail until the tag is published.

2. **Verify the version**:
   ```bash
   xiond version --long
   # Should show version: {{RELEASE_TAG}}
   ```

3. **Wait for upgrade height**: Run until upgrade height {{CALCULATED_HEIGHT}}, the node will panic.

4. **Switch binary**: Stop the node, switch to **Xion {{RELEASE_TAG}}** and restart.

## Expected Upgrade Result
When the upgrade block height is reached, Xion will panic and stop. The chain will continue when validators with >2/3 voting power complete their upgrades.

## Rollback Plan
In case of unexpected issues, the upgrade can be skipped:
```bash
xiond start --unsafe-skip-upgrade {{CALCULATED_HEIGHT}}
```

## Release Links
- **GitHub Release**: https://github.com/burnt-labs/xion/releases/tag/{{RELEASE_TAG}}
- **Full Changelog**: [{{PREVIOUS_VERSION}}...{{RELEASE_TAG}}](https://github.com/burnt-labs/xion/compare/{{PREVIOUS_VERSION}}...{{RELEASE_TAG}})
