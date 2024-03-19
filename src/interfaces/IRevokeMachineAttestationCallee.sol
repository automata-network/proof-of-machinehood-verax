// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

/**
 * @title PoM Attestation Revocation Interface
 * @notice This interface is currently reserved for future implementation that allows
 * direct revocation of PoM Attestation that can be submitted directly by the user
 * @notice it is to be called directly by the entrypoint, via the evokeMachinehoodAttestation() method
 */

interface IRevokeMachinehoodAttestationCallee {
    /**
     * @dev this method MUST be made callable only by the PoM entrypoint contract
     * @param attestationId the id of the attestation to be revoked
     * @param payload data used to verify the legitimacy of the revocation request
     */
    function verifyRevocationPayload(bytes32 attestationId, bytes[] calldata payload) external returns (bool success);
}