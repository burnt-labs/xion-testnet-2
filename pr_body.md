# 🚀 Xion v22.0.0 Upgrade

This pull request implements the upgrade to **Xion v22.0.0** for the Xion testnet.

## 📋 Overview

- **Upgrade Height**: `7116000` (estimated: ~2 days from current block)
- **Chain ID**: `xion-testnet-2` (in-place migration)
- **Release**: https://github.com/burnt-labs/xion/releases/tag/v22.0.0
- **Proposal**: `proposals/038-upgrade-v22.json`
- **Governance Deposit**: 1000000000uxion
- **Expedited**: false

## 📊 Changes Summary

- **Status**: Future release (comparison data will be available when release is published)
- **Changelog**: Will be available at [Compare v21.0.0...v22.0.0](https://github.com/burnt-labs/xion/compare/v21.0.0...v22.0.0)

## 📁 Files Modified

### Governance & Upgrade Files
- **Proposal**: `proposals/038-upgrade-v22.json`
  - Upgrade height: `7116000`
  - Chain upgrade to v22.0.0
  - Points to release config: `releases/v22.json`

- **Release Config**: `releases/v22.json`
  - Binary URLs for all platforms (darwin/linux, amd64/arm64)
  - SHA256 checksums for security verification

- **Release Notes**: `release_notes/v22.md`
  - Detailed changelog and upgrade information
  - Generated using AI analysis of GitHub comparison data

## 🔒 Security & Verification

### Binary Checksums

⚠️ **Placeholder checksums** (release not yet published):
- Checksums will be updated automatically when v22.0.0 is released
- Binary URLs point to the expected release location

## ⚠️ Important Notes for Validators

### Pre-Upgrade Checklist
- [ ] **Backup**: Full snapshot of `.xiond` directory
- [ ] **Critical**: Backup `.xiond/data/priv_validator_state.json` after stopping node
- [ ] **Verify**: Binary version before starting post-upgrade
- [ ] **Monitor**: Network upgrade progress

### System Requirements
- **RAM**: 16GB recommended for smooth upgrade
- **Disk**: Ensure sufficient space for state growth
- **Network**: Stable connection during upgrade window

### Upgrade Process
1. **Wait** for upgrade height `7116000`
2. **Node will panic** with upgrade message at target height
3. **Stop node** and switch to v22.0.0 binary
4. **Restart** with `xiond start`
5. **Monitor** for successful chain continuation

### Emergency Procedures
```bash
# Skip upgrade if issues occur
xiond start --unsafe-skip-upgrade 7116000
```

## 🔗 Resources

- **GitHub Release**: https://github.com/burnt-labs/xion/releases/tag/v22.0.0
- **Upgrade Proposal**: `proposals/038-upgrade-v22.json`
- **Technical Documentation**: `release_notes/v22.md`
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
- Workflow run: 52
- Commit: f7677c580305ab2444e8e40baa28b72a4f608011
- Timestamp: 2025-09-02 13:09:38 UTC


## 📝 Detailed Release Notes

<details>
<summary>Click to expand AI-generated upgrade guide</summary>

```markdown
null
```
</details>
