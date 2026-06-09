# AGENTS.md

This repo contains governance proposals, release notes, and Cosmovisor release metadata for `xion-testnet-2`.

## Critical Proposal Rules

- Submitted governance proposals are immutable. If a proposal has already been submitted on-chain, do not edit its JSON to "fix" it. Add a new proposal using the next proposal number.
- Keep submitted proposal files as historical records of what was submitted, including mistakes.
- Replacement proposals should say which proposal they replace in `summary`.
- Proposal filenames must use the next numeric prefix, for example `061-upgrade-v30.json`, `062-upgrade-v30.json`.

## Upgrade Proposal `info` URLs

- Upgrade proposal `plan.info` must point to the canonical `main` branch release file:

```json
"info": "https://raw.githubusercontent.com/burnt-labs/xion-testnet-2/main/releases/v30.json"
```

- Do not use feature branches such as `chore/rebranding` in submitted proposal `info` URLs.
- Do not invent special release filenames such as `v30-verona-rebrand.json` unless the repo has explicitly adopted that naming. Existing convention is `releases/v<MAJOR>.json`.
- Before creating an upgrade proposal, confirm the referenced release file exists and parses:

```bash
jq . releases/v30.json >/dev/null
```

## Release Files

- Release files live in `releases/v<MAJOR>.json`.
- Binary URLs must point to real assets in `burnt-labs/xion` releases.
- Include checksum suffixes in the same format as prior releases:

```text
?checksum=sha256:<hash>
```

- Verify asset filenames match the release version. For v30, use `xiond_30.0.0_*`, not stale filenames from earlier versions.

## Validation

Run these before handing off proposal or release metadata changes:

```bash
jq . proposals/<NNN-upgrade-vX>.json >/dev/null
jq . releases/vX.json >/dev/null
git diff --check
```

If changing release URLs or checksums, compare against GitHub release assets:

```bash
gh release view vX.Y.Z --repo burnt-labs/xion --json assets
```

## Verona Rebrand Context

The v30 Verona rebrand change is alias-only on denom metadata. It must preserve:

- Base denomination `uxion`
- Display denomination `XION`
- Token name `xion`
- Token symbol `XION`
- Chain ID
- Bech32 prefixes
- Module names
- Protobuf packages
- REST paths
- Balances, staking denom, mint denom, and gas denom

Expected alias additions:

- `uxion`: `uverona`, `microverona`
- `mxion`: `mverona`, `milliverona`
- `XION`: `verona`, `VERONA`
