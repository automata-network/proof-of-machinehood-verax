// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MachinehoodPortal} from "../../MachinehoodPortal.sol";
import {MachinehoodModule, ValidationPayloadStruct, AttestationPayload, DeviceType} from "../../MachinehoodModule.sol";
import {MockERC20} from "./MockERC20.sol";
import {AttestationRegistry, Attestation} from "verax-contracts/AttestationRegistry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Faucet is Ownable {
    uint256 public attestationValidityDurationInSeconds;
    AttestationRegistry public immutable attestationRegistry;
    MachinehoodPortal public immutable portal;
    MachinehoodModule public immutable module;
    MockERC20 public immutable token;

    mapping(address => bytes32) recipientToAttestation;

    error Attestation_Expired(bytes32 attestationId);
    error Attestation_Not_Registered();

    constructor(address _attestationRegistry, address _portal, address _module, address _token) {
        attestationRegistry = AttestationRegistry(_attestationRegistry);
        portal = MachinehoodPortal(_portal);
        module = MachinehoodModule(_module);
        token = MockERC20(_token);
    }

    function setAttestationValidityDuration(uint256 _newDuration) external onlyOwner {
        attestationValidityDurationInSeconds = _newDuration;
    }

    function attestationIsValid(address user) external view returns (bool) {
        bytes32 attestationId = recipientToAttestation[user];
        if (attestationId == bytes32(0)) {
            return false;
        } else {
            Attestation memory attestation = attestationRegistry.getAttestation(attestationId);
            return !_attestationHasExpired(attestation);
        }
    }

    /**
     * @notice sends 0.1 ether of MockERC20 to qualfied users
     */
    function requestTokens(address user) external {
        bytes32 attestationId = recipientToAttestation[user];
        if (attestationId == bytes32(0)) {
            revert Attestation_Not_Registered();
        }
        Attestation memory attestation = attestationRegistry.getAttestation(attestationId);
        bool attestationExpired = _attestationHasExpired(attestation);
        if (attestationExpired) {
            revert Attestation_Expired(attestationId);
        }
        uint256 amount = 0.1 ether;
        if (token.balanceOf(address(this)) < amount) {
            token.mint(address(this), 100 ether);
        }
        token.transfer(user, amount);
    }

    function attest(
        address user,
        DeviceType device,
        bytes calldata authData,
        bytes calldata clientData,
        bytes calldata attStmt
    ) external {
        {
            bytes32 walletAddress = bytes32(uint256(uint160(user)));

            ValidationPayloadStruct memory validationPayload =
                ValidationPayloadStruct({attStmt: attStmt, authData: authData, clientData: clientData});

            bytes memory encodedValidationData = abi.encode(validationPayload);
            bytes memory attestationData = abi.encode(walletAddress, device, keccak256(encodedValidationData));
            bytes[] memory validationPayloadArr = new bytes[](1);
            validationPayloadArr[0] = encodedValidationData;

            AttestationPayload memory attestationPayload = AttestationPayload({
                schemaId: module.MACHINEHOOD_SCHEMA_ID(),
                expirationDate: uint64(block.timestamp + attestationValidityDurationInSeconds),
                subject: abi.encodePacked(user), // stores the wallet address as the attestation subject
                attestationData: attestationData
            });

            portal.attest(attestationPayload, validationPayloadArr);
        }

        uint32 attestationCounter = attestationRegistry.getAttestationIdCounter();
        bytes32 attestationId = bytes32(abi.encode(attestationCounter));
        recipientToAttestation[user] = attestationId;
    }

    function _attestationHasExpired(Attestation memory attestation) private view returns (bool) {
        bool expired = block.timestamp >= attestation.attestedDate + attestationValidityDurationInSeconds;
        if (attestation.expirationDate == 0) {
            return expired;
        } else {
            return expired || block.timestamp >= attestation.expirationDate;
        }
    }
}
