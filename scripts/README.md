# Upgrade Proposal Generation

This directory contains tools for automatically generating upgrade proposal files and corresponding release files.

## Overview

The system provides two ways to create upgrade proposals:

1. **GitHub Actions Workflow** - Automated CI/CD pipeline that calls the script
2. **Manual Script** - Local script for testing and development

## Architecture

The system uses a **single source of truth** approach:

- 🎯 **Core Logic**: All file creation logic is in `scripts/create-proposal.sh`
- 🤖 **GitHub Actions**: Simple orchestration layer that calls the script
- ✅ **Benefits**: No code duplication, easy to test locally, consistent behavior

```
GitHub Actions Workflow
    ↓
calls scripts/create-proposal.sh
    ↓
creates: proposal + release + release-notes
    ↓
commits to feature branch → creates PR
```

## GitHub Actions Workflow

### Usage

1. Navigate to the **Actions** tab in the GitHub repository
2. Select the **"Create Upgrade Proposal"** workflow
3. Click **"Run workflow"** and provide the required inputs:
   - **Height**: The upgrade block height
   - **Deposit** (optional): Proposal deposit amount (default: `1000000000uxion`)
   - **Expedited** (optional): Whether this is an expedited proposal (default: `false`)

**Note**: The version number is automatically determined by scanning the `releases/` folder for the latest version and incrementing it.

### What it does

1. Calls the local script (`scripts/create-proposal.sh`) with the provided parameters
2. The script automatically determines the next version and creates all files
3. Creates a feature branch (e.g., `upgrade-proposal-v22`)
4. Commits the changes to the feature branch
5. Pushes the feature branch to the repository
6. Creates a Pull Request from the feature branch to main

### Example

Running the workflow with:
- Height: `7500000`
- Deposit: `1000000000uxion`
- Expedited: `false`

When the latest release is `v21.json`, will create:
- `proposals/041-upgrade-v22.json`
- `releases/v22.json`
- `release_notes/v22.md`

## Manual Script

### Usage

```bash
./scripts/create-proposal.sh <height> [deposit] [expedited]
```

### Examples

```bash
# Basic usage
./scripts/create-proposal.sh 7500000

# With custom deposit and expedited flag
./scripts/create-proposal.sh 8000000 2000000000uxion true
```

### Parameters

- `height` (required): Upgrade block height
- `deposit` (optional): Proposal deposit amount (default: `1000000000uxion`)
- `expedited` (optional): Expedited proposal flag (default: `false`)

**Note**: The version number is automatically determined by scanning the `releases/` folder for the latest version and incrementing it.

## Environment Variables

The system uses environment variables for managing placeholder values in binary checksums. These can be customized at the workflow level or when running the script locally.

### Default Placeholders

```bash
PLACEHOLDER_CHECKSUM_DARWIN_AMD64="--ADD-HERE-YOUR-VALUE--"
PLACEHOLDER_CHECKSUM_DARWIN_ARM64="--ADD-HERE-YOUR-VALUE--"
PLACEHOLDER_CHECKSUM_LINUX_AMD64="--ADD-HERE-YOUR-VALUE--"
PLACEHOLDER_CHECKSUM_LINUX_ARM64="--ADD-HERE-YOUR-VALUE--"
```

### Customizing Placeholders

You can override these values when running the script:

```bash
# Use custom placeholders
PLACEHOLDER_CHECKSUM_DARWIN_AMD64="DARWIN-AMD64-CHECKSUM-HERE" \
PLACEHOLDER_CHECKSUM_LINUX_AMD64="LINUX-AMD64-CHECKSUM-HERE" \
./scripts/create-proposal.sh 7500000
```

For the GitHub Actions workflow, update the `env` section at the top of the workflow file.

## File Structure

### Proposal Files (`proposals/XXX-upgrade-vYY.json`)

Contains the governance proposal for the software upgrade:

```json
{
  "messages": [
    {
      "@type": "/cosmos.upgrade.v1beta1.MsgSoftwareUpgrade",
      "authority": "xion10d07y265gmmuvt4z0w9aw880jnsr700jctf8qc",
      "plan": {
        "name": "v22",
        "height": "7500000",
        "info": "https://raw.githubusercontent.com/burnt-labs/xion-testnet-2/main/releases/v22.json",
        "upgraded_client_state": null
      }
    }
  ],
  "title": "Software Upgrade v22",
  "summary": "Software Upgrade v22",
  "deposit": "1000000000uxion",
  "expedited": false
}
```

### Release Files (`releases/vYY.json`)

Contains binary download links and checksums:

```json
{
  "binaries": {
    "darwin/amd64": "https://github.com/burnt-labs/xion/releases/download/v22.0.0/xiond_22.0.0_darwin_amd64.tar.gz?checksum=sha256:--ADD-HERE-YOUR-VALUE--",
    "darwin/arm64": "https://github.com/burnt-labs/xion/releases/download/v22.0.0/xiond_22.0.0_darwin_arm64.tar.gz?checksum=sha256:--ADD-HERE-YOUR-VALUE--",
    "linux/amd64": "https://github.com/burnt-labs/xion/releases/download/v22.0.0/xiond_22.0.0_linux_amd64.tar.gz?checksum=sha256:--ADD-HERE-YOUR-VALUE--",
    "linux/arm64": "https://github.com/burnt-labs/xion/releases/download/v22.0.0/xiond_22.0.0_linux_arm64.tar.gz?checksum=sha256:--ADD-HERE-YOUR-VALUE--"
  }
}
```

### Release Notes Files (`release_notes/vYY.md`)

Contains structured release notes with sections for changes, contributors, and links:

```markdown
# Xion v22 Release Notes

## Overview
Xion v22.0.0 includes [--ADD-HERE-YOUR-DESCRIPTION--]. This is the initial release with only v22.0.0 available.

## What's Changed
### v22.0.0 (Only Version)
#### Major Changes
- **[Feature Name]**: [Description] by [@username](https://github.com/username) in [#PR](https://github.com/burnt-labs/xion/pull/PR)

## Upgrade Information
- **Upgrade Height**: 7500000 (testnet)
- **Proposal Number**: 041
```

## Post-Generation Steps

After generating the files, you'll need to:

1. **Update checksums**: Replace `--ADD-HERE-YOUR-VALUE--` in the release file with actual SHA256 checksums from the GitHub release
2. **Fill in release notes**: Replace placeholder content in the release notes with actual changes, contributors, and PR links
3. **Review proposal details**: Verify the upgrade height and other parameters
4. **Submit proposal**: Use the generated JSON file to submit the governance proposal on-chain

## Automatic Numbering

The system automatically handles proposal numbering:

- Scans existing proposal files to find the highest number
- Increments by 1 for the new proposal
- Handles gaps in numbering (if files are deleted or missing)
- Uses zero-padded 3-digit format (001, 002, 041, etc.)

## Requirements

- `jq` (for JSON formatting) - automatically installed in GitHub Actions
- Bash shell
- Write access to the repository

## Troubleshooting

### Common Issues

1. **Permission denied**: Make sure the script is executable (`chmod +x scripts/create-proposal.sh`)
2. **File already exists**: The system will increment the proposal number if a file already exists
3. **Invalid JSON**: The script uses `jq` to validate and format JSON files

### Manual Cleanup

If you need to remove generated files:

```bash
# Remove specific proposal and release
rm proposals/041-upgrade-v22.json
rm releases/v22.json
```
