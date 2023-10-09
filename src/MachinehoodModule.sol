// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AbstractModule, AttestationPayload} from "verax-contracts/interface/AbstractModule.sol";
import {AttestationVerificationBase} from "./lib/verification/AttestationVerificationBase.sol";
import {Ownable} from "solady/Milady.sol";

contract MachinehoodModule is AbstractModule, Ownable {
    // keccak256(bytes("bytes32 walletAddress, uint8 deviceType, bytes32 proofHash"))
    bytes32 public constant MACHINEHOOD_SCHEMA_ID = 0xfcd7908635f4a15e4c4ae351f13f9aa393e56e67aca82e5ffd3cf5c463464ee7;

    struct ValidationPayloadStruct {
        bytes attStmt;
        bytes authData;
        bytes clientData;
    }

    enum DeviceType {
        INVALID,
        ANDROID
    }

    // DeviceType => attestation verification contract address
    mapping(DeviceType => address) private verifyingAddresses;

    event SupportedDeviceUpdated(DeviceType device, address verify);

    error Attestation_Should_Not_Expire();
    error Invalid_Schema_Id();
    error Invalid_Proof_Hash();
    error Unsupported_Device_Type();

    constructor() {
        _initializeOwner(msg.sender);
    }

    function configureSupportedDevice(DeviceType device, address verify) external onlyOwner {
        verifyingAddresses[device] = verify;
        emit SupportedDeviceUpdated(device, verify);
    }

    function run(AttestationPayload memory attestationPayload, bytes memory validationPayload, address, uint256)
        public
        override
    {
        if (attestationPayload.schemaId != MACHINEHOOD_SCHEMA_ID) {
            revert Invalid_Schema_Id();
        }

        // Interestingly, for an expirationDate greater than zero
        // Verax contracts do not seem to bother checking whether an Attestation has expired or not
        // Enforcing a zero expiration date would be explicitly stating that:
        // Machinehood Attestation should remain valid indefinitely once verified.
        if (attestationPayload.expirationDate > 0) {
            revert Attestation_Should_Not_Expire();
        }

        (bytes32 walletAddress, DeviceType deviceType, bytes32 proofHash) =
            abi.decode(attestationPayload.attestationData, (bytes32, DeviceType, bytes32));

        if (proofHash != keccak256(validationPayload)) {
            revert Invalid_Proof_Hash();
        }

        ValidationPayloadStruct memory decoded = abi.decode(validationPayload, (ValidationPayloadStruct));

        address verify = verifyingAddresses[deviceType];
        if (verify == address(0)) {
            revert Unsupported_Device_Type();
        }

        AttestationVerificationBase(verify).verifyAttStmt(
            walletAddress, decoded.attStmt, decoded.authData, decoded.clientData
        );
    }
}
