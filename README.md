# Integrating Machinehood with Verax Attestation Registry
This repository provides the implementation for Machinehood attestations on Verax by integrating [Machinehood Contracts](https://github.com/automata-network/machinehood-contracts) and [Verax Attestation Registry](https://github.com/Consensys/linea-attestation-registry). For more information about Machinehood, please refer to the provided [documentation]((https://docs.ata.network/automata-2.0/proof-of-machinehood)) and explore the [Machinehood repository](https://github.com/automata-network/machinehood-contracts).

## Repository Overview
We implemented a [portal](https://docs.ver.ax/verax-documentation/core-concepts/portals) and [module](https://docs.ver.ax/verax-documentation/core-concepts/modules) contracts designed to integrate with the Verax Attestation Registry. To provide a better understanding of how they work, we included a Faucet implementation contract as an example that verifies the user's submitted attestation, then distributes tokens to the users upon successful verification.

To receive tokens from the faucet, users must first attest their device. After submitting the attestation to the Verax Attestation Registry, they can then request tokens from the faucet contract. Each valid attestation allows users to claim tokens for a predefined duration, e.g. 7 days (may vary depending on the configuration set by the contract owner). Once an attestation expires, users are required to re-submit an attestation to confirm they still own a supported device and continue receiving tokens.

The attestation confirms that the user had control over a specific device at the time of its generation. However, the reliability of this attestation diminishes over time. To balance user experience and security, each attestation is designed with a set expiration period. Click [here](https://github.com/automata-network/machinehood-contracts#does-the-attestation-prove-that-users-owns-the-device) to learn more on how does the expiration period affect security of an attestation.

## Schema Overview
This section outlines the schema utilized by this repository, which was created on the Linea Testnet.

| Field | Content |
| ---- | ---- |
| Schema ID | 0xfcd7908635f4a15e4c4ae351f13f9aa393e56e67aca82e5ffd3cf5c463464ee7 |
| Schema Name | Machinehood Attestation |
| Schema Description | https://docs.ata.network/automata-2.0/proof-of-machinehood |
| Schema Context | NONE |
| Schema String | bytes32 walletAddress, uint8 deviceType, bytes32 proofHash |

The schema comprises three fields:
- `walletAddress`: The wallet address of the user who submitted the attestation.
- `deviceType`: The type of device being attested by the user.
- `proofHash`: The hash of the attestation proof, validated by the module through the [Machinehood Library](https://github.com/automata-network/machinehood-contracts).

Schema Significance: The schema indicates that the owner of the `walletAddress` is attesting to owning a device of `deviceType` and provides a proof whose hash is `proofHash`.

## What are included in this repo?
- `Portal`: 
- `Module`:
- `Faucet`:
- `DummyToken`: 

## Contracts Address

## For Developers: Local Development