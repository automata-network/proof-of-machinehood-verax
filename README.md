# Integrating Proof of Machinehood (POM) with Verax Attestation Registry

[![License](https://img.shields.io/badge/license-GPL3.0-green.svg)](LICENSE)

This repository provides the implementation for POM attestations on Verax by integrating [POM Contracts](https://github.com/automata-network/proof-of-machinehood-contracts) and [Verax Attestation Registry](https://github.com/Consensys/linea-attestation-registry). For more information about POM, please refer to the provided [documentation]((https://docs.ata.network/automata-2.0/proof-of-machinehood)) and explore the [POM contracts repository](https://github.com/automata-network/proof-of-machinehood-contracts).

## Repository Overview
We implemented a [portal](https://docs.ver.ax/verax-documentation/core-concepts/portals) and [module](https://docs.ver.ax/verax-documentation/core-concepts/modules) contracts designed to integrate with Verax Attestation Registry. To provide a better understanding of how they work, we included a [Faucet demo](./src/examples//00_faucet/) as an example that verifies the user's submitted attestation, then distributes tokens to the users upon successful verification.

To receive tokens from the faucet, users must first attest their device. After submitting the attestation to the Verax Attestation Registry, they can then request tokens from the faucet contract. Each valid attestation allows users to claim tokens for a predefined duration, e.g. 7 days (may vary depending on the configuration set by the contract owner). Once an attestation expires, users are required to re-submit an attestation to confirm they still own a supported device and continue receiving tokens.

The attestation confirms that the user had control over a specific device at the time of its generation. However, the reliability of this attestation diminishes over time. To balance user experience and security, each attestation is designed with a set expiration period. Click [here](https://github.com/automata-network/proof-of-machinehood-contracts#does-the-attestation-prove-that-users-owns-the-device) to learn more on how does the expiration period affect security of an attestation.

## Schema Overview
This section outlines the schema utilized by this repository, which was created on the Linea Testnet.

| Field | Content |
| ---- | ---- |
| Schema ID | 0xfcd7908635f4a15e4c4ae351f13f9aa393e56e67aca82e5ffd3cf5c463464ee7 |
| Schema Name | Proof of Machinehood Attestation |
| Schema Description | https://docs.ata.network/automata-2.0/proof-of-machinehood |
| Schema Context | NONE |
| Schema String | `bytes32 walletAddress, uint8 deviceType, bytes32 proofHash` |

The schema comprises three fields:
- `walletAddress`: The wallet address of the user who submitted the attestation.
- `deviceType`: The type of device being attested by the user.
- `proofHash`: The hash of the attestation proof, validated by the module through the [POM Library](https://github.com/automata-network/proof-of-machinehood-contracts).

Schema Significance: The schema indicates that the owner of the `walletAddress` is attesting to owning a device of `deviceType` and provides a proof whose hash is `proofHash`.

## What are included in this repo?
- `MachinehoodPortal.sol`: This is the entrypoint contract where users can submit POM attestations using their device built-in authenticator.
- `MachinehoodModule.sol`: The module contract that implements on-chain validation logic.

### Faucet Demo:
The workflow on interacting with the demo:
1. The user provides a wallet address that they intend to receive the tokens.
2. The wallet address needs to be authenticated by the user's device.
3. After getting confirmation of the attestation's validity, users may click on the Request Tokens button to receive 0.1 $MOCK to the wallet address provided on step 1. A confirmation window will appear prompting users to whether download a copy of their attestation data or not. This is optional, but can be useful for debugging.

The demo consists of the following:
- `Faucet.sol`: This is the Faucet contract that retrieves attestations from Verax Attestation Registry and sends tokens to the user's wallet.
- `MockERC20.sol`: The contract for the token that is distributed by the faucet.

## For Developers: Test It Out On Your Machine

You must make sure that you have met the prerequisites below.

- Install [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Install the dependencies, by running:

```bash
forge install
```

Step 1: Make a copy of `.env` using the example provided.

```bash
cp .env.example .env
```

You may skip directly to the **Contract Deployment** section if you intend to deploy the contracts on a live EVM network.

Step 2: Source the envrionment.

```bash
source .env
```

Step 3: Instantiate a local fork of the Linea mainnet.

```bash
anvil --fork-url $FORK_URL
```

### Contract Deployment

> ℹ️ **NOTE**
> 
> If you are getting contract addresses that are different from the addresses provided in `.env.example`,
> you must run `source .env` each time before proceeding to the next step.

Step 4: Open a new terminal, begin deploying `MachinehoodModule.sol`.

```bash
forge script DeployMachinehoodModuleScript --rpc-url $RPC_URL --broadcast
```

Step 5: Deploy `MachinehoodPortal.sol`.

```bash
forge script DeployMachinehoodPortalScript --rpc-url $RPC_URL --broadcast
```

Step 6: **Required**: if you are deploying to Anvil, otherwise skip this step.

> ℹ️ **NOTE**
> 
> You must make sure that your deployment address has been whitelisted as a Verax issuer, before you can
> register your schema, module and portal to the registry.
> On the local Anvil network, you can use a [special RPC method](https://book.getfoundry.sh/reference/anvil/#custom-methods) that allows you to impersonate the registry owner to whitelist the deployment address.

Run the command below, to get whitelisted:

```bash
./script/impersonate.sh
```

ℹ️ **TIP**: If you are having issues running the Shell script, most of the time it can be resolved by running:

```bash
chmod +x ./script/impersonate.sh
```

Step 7: Register the schema, `MachindhoodModule` and `MachinehoodPortal`

```bash
forge script VeraxConfigurationScript --rpc-url $RPC_URL --broadcast
```

You are all set! Now you may proceed to test out the [demo](./src/examples/00_faucet/)! :)