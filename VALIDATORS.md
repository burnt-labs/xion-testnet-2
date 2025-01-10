# Validator Guide

Follow this guide to become a genesis validator on the xion-testnet-2 chain. This guide walks you through creating a `gentx` file that will be added to the validator chain. A `gentx` is a special transaction included in the genesis file that accomplishes three things:

1. Registers your validator account as a validator operator account.
2. Self-delegates the specified amount of XION tokens for staking.
3. Links the validator operator account with a node pubkey used to sign blocks.

All validators that wish to be included in the new Xion testnet chain can follow the steps below.

## Networks

- New Xion testnet: `xion-testnet-2`

## Prerequisites

- [Xion Core Repository](https://github.com/xion-money/core)
- [Go 1.22+](https://go.dev/dl/)

## Timeline (Expected)

### Share [genesis.json](https://raw.githubusercontent.com/burnt-labs/xion-testnet-2/refs/heads/main/config/genesis.json) and start collecting gen_txs from the validators

- Tue Jan 7 2025 16:00:00 GMT-0500 (EST)
- Tue Jan 7 2025 21:00:00 GMT+0000 (UTC)

### Finish collecting gen_txs, build, and share `genesis.json`

- Wed Jan 28 2025 11:00:00 GMT-0500 (EST)
- Wed Jan 28 2025 16:00:00 GMT+0000 (UTC)

### Launch xion-testnet-2 network

- Wed Jan 29 2025 11:00:00 GMT-0500 (EST)
- Wed Jan 29 2025 16:00:00 GMT+0000 (UTC)

## Set Up a Validator

Set up a new validator on a new machine by following the steps outlined in [Run a Node](https://docs.burnt.com/xion/nodes-and-validators/run-a-node).

After [configuring your general settings](https://docs.burnt.com/xion/nodes-and-validators/run-a-node/configure-the-xion-daemon), continue to the next section.

## GenTx

Complete the following steps on your new validator's machine.

1. Download and install the Xion release [v14.1.1](https://github.com/burnt-labs/xion/releases/tag/v14.1.1):

    ```sh
    # Set environment variable for the xiond binary name
    export XIOND_BINARY=xiond-$(uname -s | awk '{print tolower($0)}')-$(uname -m | sed 's/aarch/amd/')

    # Download the binary
    wget https://github.com/burnt-labs/xion/releases/download/v14.1.1/$XIOND_BINARY

    # Verify the checksum
    wget https://github.com/burnt-labs/xion/releases/download/v14.1.1/checksum.txt
    grep $XIOND_BINARY checksum.txt | sha256sum -c -

    # Move the binary to a directory in your PATH
    sudo mv $XIOND_BINARY /usr/local/bin/xiond
    ```

2. Prepare your environment:

    ```sh
    # Download the genesis.json genesis file
    wget https://raw.githubusercontent.com/burnt-labs/xion-testnet-2/refs/tags/prelaunch/config/genesis.json

    # Move the genesis file to the config location
    mv ./genesis.json ~/.xion/config/genesis.json
    ```

3. Execute GenTx:

    ```sh
    MONIKER="<preffered_moniker>"
    xiond genesis gentx validator 1000000uxion \
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

4. Upload the generated GenTx file to this repository's [gentx](https://github.com/burnt-labs/xion-testnet-2/tree/prelaunch/config) folder via a Pull Request (PR):

    ```sh
    cp ~/.xion/config/gentx/*.json ./gentx/
    git add ./gentx/*.json
    git commit -m "Add gentx for <your-moniker>"
    git push origin <your-branch>
    ```

5. Create a Pull Request to merge your branch into the main repository.

## Additional Notes

- Ensure your node is properly configured and running before submitting your GenTx.
- Double-check all the details in your GenTx command to avoid any errors.
- If you encounter any issues, refer to the [Xion documentation](https://docs.xion.burnt.com/) or reach out to the community for support.
