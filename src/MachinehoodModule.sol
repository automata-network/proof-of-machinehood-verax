// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AbstractModule, AttestationPayload} from "verax-contracts/abstracts/AbstractModule.sol";
import {AttestationVerificationBase} from "@automata-network/machinehood-contracts/AttestationVerificationBase.sol";
import {Ownable} from "solady/Milady.sol";

struct ValidationPayloadStruct {
    bytes attStmt;
    bytes authData;
    bytes clientData;
}

enum DeviceType {
    INVALID,
    ANDROID,
    WINDOWS,
    YUBIKEY,
    SELFCLAIM
}

contract MachinehoodModule is AbstractModule, Ownable {
    // keccak256(bytes("bytes32 walletAddress, uint8 deviceType, bytes32 proofHash"))
    bytes32 public constant MACHINEHOOD_SCHEMA_ID = 0xfcd7908635f4a15e4c4ae351f13f9aa393e56e67aca82e5ffd3cf5c463464ee7;

    // DeviceType => attestation verification contract address
    mapping(DeviceType => address) private verifyingAddresses;

    event SupportedDeviceUpdated(DeviceType device, address verify);

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
        view
        override
    {
        if (attestationPayload.schemaId != MACHINEHOOD_SCHEMA_ID) {
            revert Invalid_Schema_Id();
        }

        (bytes32 walletAddress, DeviceType deviceType, bytes32 proofHash) =
            abi.decode(attestationPayload.attestationData, (bytes32, DeviceType, bytes32));

        if (proofHash != keccak256(validationPayload)) {
            revert Invalid_Proof_Hash();
        }

        ValidationPayloadStruct memory decoded = abi.decode(validationPayload, (ValidationPayloadStruct));

        address verify = verifyingAddresses[deviceType];

        // TEMP: bypass Apple lib

        if (verify == address(0) && deviceType != DeviceType.SELFCLAIM) {
            revert Unsupported_Device_Type();
        }

        if (deviceType != DeviceType.SELFCLAIM) {
            (bool success, string memory reason) = AttestationVerificationBase(verify).verifyAttStmt(
                abi.encodePacked(walletAddress), decoded.attStmt, decoded.authData, decoded.clientData
            );

            require(success, reason);
        }
    }
}
