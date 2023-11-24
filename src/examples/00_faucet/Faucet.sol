// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MockERC20} from "./MockERC20.sol";
import {AttestationRegistry, Attestation} from "verax-contracts/AttestationRegistry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Faucet is Ownable {
    uint256 public attestationValidityDurationInSeconds;
    /// @dev this is necessary because we want attestations with the machinehood schema to be created
    /// from the official portal only
    address public immutable machinehoodPortal;
    AttestationRegistry public immutable attestationRegistry;
    MockERC20 public immutable token;
    // keccak256(bytes("bytes32 walletAddress, uint8 deviceType, bytes32 proofHash"))
    bytes32 public constant MACHINEHOOD_SCHEMA_ID = 0xfcd7908635f4a15e4c4ae351f13f9aa393e56e67aca82e5ffd3cf5c463464ee7;

    error Attestation_Expired_Or_Invalid(bytes32 attestationId);

    constructor(address _attestationRegistry, address _portal, address _token) {
        attestationRegistry = AttestationRegistry(_attestationRegistry);
        token = MockERC20(_token);
        machinehoodPortal = _portal;
    }

    function setAttestationValidityDuration(uint256 _newDuration) external onlyOwner {
        attestationValidityDurationInSeconds = _newDuration;
    }

    function attestationIsValid(bytes32 attestationId) external view returns (bool) {
        Attestation memory attestation = attestationRegistry.getAttestation(attestationId);
        return _attestationIsValid(attestation);
    }

    /**
     * @notice sends 0.1 ether of MockERC20 to qualfied users
     */
    function requestTokens(bytes32 attestationId) external {
        Attestation memory attestation = attestationRegistry.getAttestation(attestationId);
        bool validAttestation = _attestationIsValid(attestation);
        if (!validAttestation) {
            revert Attestation_Expired_Or_Invalid(attestationId);
        }
        uint256 amount = 0.1 ether;
        (bytes32 walletAddress,,) = abi.decode(attestation.attestationData, (bytes32, uint8, bytes32));
        address user = address(uint160(uint256(walletAddress)));
        token.mint(user, amount);
    }

    function _attestationIsValid(Attestation memory attestation) private view returns (bool) {
        // check expiration
        bool expired = block.timestamp >= attestation.attestedDate + attestationValidityDurationInSeconds;
        if (attestation.expirationDate != 0) {
            expired = expired || block.timestamp >= attestation.expirationDate;
        }

        // check schema
        bool schemaMatched = attestation.schemaId == MACHINEHOOD_SCHEMA_ID;

        // check portal
        bool portalMatched = attestation.portal == machinehoodPortal;

        return !expired && schemaMatched && portalMatched;
    }
}
