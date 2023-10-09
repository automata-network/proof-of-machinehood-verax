// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AbstractModule, AttestationPayload} from "verax-contracts/interface/AbstractModule.sol";
import {AttestationVerificationBase} from "./lib/AttestationVerificationBase.sol";

contract MachinehoodModule is AbstractModule {
    bytes32 public constant MACHINEHOOD_SCHEMA_ID = 0xf99d88e9eaa031f7680ac5140274e9fa71ee9a935ada88c57834946513781925;

    struct ValidationPayloadStruct {
        DeviceType device;
        bytes attStmt;
        bytes authData;
        bytes clientData;
    }

    enum DeviceType {
        INVALID,
        ANDROID
    }

    // DeviceType => DeviceType string => attestation verification contract address
    // 1. DeviceType.ANDROID => "android-safety-net"
    mapping(DeviceType => mapping(string => address)) private verifyingAddresses;

    error Attestation_Should_Not_Expire();
    error Invalid_Schema_Id();
    error Invalid_Proof_Hash();
    error Unsupported_Device_Type();

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

        (bytes32 walletAddress, string memory deviceType, bytes32 proofHash) =
            abi.decode(attestationPayload.attestationData, (bytes32, string, bytes32));

        if (proofHash != keccak256(validationPayload)) {
            revert Invalid_Proof_Hash();
        }

        ValidationPayloadStruct memory decoded = abi.decode(validationPayload, (ValidationPayloadStruct));

        address verify = verifyingAddresses[decoded.device][deviceType];
        if (verify == address(0)) {
            revert Unsupported_Device_Type();
        }

        AttestationVerificationBase(verify).verifyAttStmt(decoded.attStmt, decoded.authData, decoded.clientData);
    }
}
