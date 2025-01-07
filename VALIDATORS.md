# Validator guide

Follow this guide to be a genesis validator on the xion-testnet-2 chain. This guide walks you through making a `gentx` file that will be added to the validator chain. A `gentx` is a special transaction included in the genesis file that accomplishes three things:

1. Registers your validator account as a validator operator account.
2. Self-delegates the specified amount of XION tokens for staking.
3. Links the validator operator account with a node pubkey used to sign blocks.

All validators that wish to be included in the new Xion testnet chain can follow the steps below.

## Networks

- New Xion testnet: `xion-testnet-2`

## Prerequisites

- [https://github.com/xion-money/core](https://github.com/xion-money/core)
- [Go 1.22+](https://go.dev/dl/)

## Timeline (Expected)

### Share `gentx/gentx-genesis.json` and start to collect gen_txs from the validators

- Tue Jan 7 2025 16:00:00 GMT-0500 (EST)
- Tue Jan 7 2025 16:00:00 GMT+0000 (UTC)

### Finish collecting gen_txs build and share `genesis.json`

- Wed Jan 28 2025 11:00:00 GMT-0500 (EST)
- Tue Jan 28 2025 16:00:00 GMT+0000 (UTC)

### Launch xion-testnet-2 network

- Wed Jan 29 2025 11:00:00 GMT-0500 (EST)
- Wed Jan 29 2025 16:00:00 GMT+0000 (UTC)


## Set up a validator

Set up a new validator on a new machine by following the steps outlined in [Run a Node](https://docs.burnt.com/xion/nodes-and-validators/run-a-node).  

After [configuring your general settings](https://docs.burnt.com/xion/nodes-and-validators/run-a-node/configure-the-xion-daemon), continue to the next section.  

## GenTx

Complete the following steps on your new validator's machine.  

1. Download and install xion release [v14.1.1](https://github.com/burnt-labs/xion/releases/tag/v14.1.1)

2. Prepare your environment:

    ```sh
    # install or move penultimate-genesis.json to server
    wget 

    # move genesis to config location
    mv ./penultimate-genesis.json ~/.xion/config/genesis.json
    ```

3. Execute GenTx:

    ```sh
    xiond gentx validator 1000000uxion \
        --chain-id="xion-testnet-2" \
        --pubkey=$(xiond comet show-validator) \
        --min-self-delegation=1 \
        --moniker="$MONIKER" \
        --details="Trusted security provider for Xion Network and projects building on Xion." \
        --commission-rate="0.1" \
        --commission-max-rate="0.2" \
        --commission-max-change-rate="0.01" \ 
        --ip="0.0.0.0"
    ```

4. Upload the generated GenTx file to this repository's gentx folder via PR:

    ```sh
    ls ~/.xion/config/gentx/*
    ```
