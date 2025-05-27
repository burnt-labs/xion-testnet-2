# Xion Testnet-2 Full Node Setup Guide

This guide will help you set up a full node for the Xion testnet-2 network using `xiond`

## Prerequisites

- **Linux/macOS** (instructions are for Unix-like systems)
- **At least 2 CPU cores, 4GB RAM, 100GB+ disk space**

## 1. Install xiond Binary

Download the latest release and install:
<https://github.com/burnt-labs/xion/releases>

## 2. Initialize Node

Replace `<moniker>` with your node name:

```sh
xiond init <moniker> --chain-id xion-testnet-2
```

## 3. Download Genesis File

```sh
wget -O ~/.xion/config/genesis.json https://raw.githubusercontent.com/burnt-labs/xion-testnet-2/main/config/genesis.json
```

## 4. Configure Peers

Edit `~/.xiond/config/config.toml` and set persistent peers. Example:

```sh
persistent_peers = "<peer1>,<peer2>,..."
```

You can find up-to-date peer addresses in the [official Discord](https://discord.gg/burnt) or community channels.

## 5. Configure Minimum Gas Price

Edit `~/.xiond/config/app.toml`:

```sh
minimum-gas-prices = "0.001uxion"
```

## 6. Start the Node

```sh
xiond start
```

## 7. Monitor Logs

```sh
tail -f ~/.xiond/logs/xiond.log
```

## Troubleshooting

- Ensure ports `26656` (P2P) and `26657` (RPC) are open.
- If you encounter issues, check the logs and reach out on [Discord](https://discord.gg/burnt).

---

For more details, see the [Xion documentation](https://docs.burnt.com/xion/).
