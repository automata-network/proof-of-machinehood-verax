// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {AbstractPortal, AttestationRegistry} from "verax-contracts/abstracts/AbstractPortal.sol";
import {AttestationPayload, Attestation} from "verax-contracts/types/Structs.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {LibBitmap} from "solady/utils/LibBitmap.sol";
import {
    POMEntrypoint,
    NativeAttestPlatform,
    WebAuthNAttestPlatform,
    WebAuthNAttestationSchema,
    NativeAttestationSchema,
    AttestationStatus
} from "@automata-network/proof-of-machinehood-contracts/POMEntrypoint.sol";

contract MachinehoodEntrypointPortal is Ownable, AbstractPortal, POMEntrypoint {
    using LibBitmap for LibBitmap.Bitmap;

    /// @dev bitmap is used to keep track of attestation data collision
    /// this prevents attackers from re-submitting attested data
    LibBitmap.Bitmap internal proofBitmap;

    mapping(WebAuthNAttestPlatform => address) public webAuthNVerifiers;
    mapping(NativeAttestPlatform => address) public nativeVerifiers;
    mapping(bytes32 => bytes32) nativeDeviceAttestations;

    bool private _unlock;

    /// @notice Error thrown when trying to improperly make attestations
    error No_External_Attestation();
    error Attestation_Already_Exists();

    constructor(address[] memory modules, address router) AbstractPortal(modules, router) {
        require(modules.length == 0);
        _initializeOwner(msg.sender);
    }

    modifier lock() {
        _unlock = true;
        _;
        _unlock = false;
    }

    modifier locked() {
        if (!_unlock) {
            revert No_External_Attestation();
        }
        _;
    }

    /// @inheritdoc AbstractPortal
    function withdraw(address payable to, uint256 amount) external override {}

    function configureWebAuthNLib(WebAuthNAttestPlatform platform, address lib) external onlyOwner {
        webAuthNVerifiers[platform] = lib;
    }

    function configureNativeLib(NativeAttestPlatform platform, address lib) external onlyOwner {
        nativeVerifiers[platform] = lib;
    }

    function webAuthNAttestationSchemaId() public pure override returns (bytes32 WEBAUTHN_MACHINEHOOD_SCHEMA_ID) {
        // keccak256(bytes("bytes32 walletAddress, uint8 deviceType, bytes32 proofHash"))
        WEBAUTHN_MACHINEHOOD_SCHEMA_ID = 0xfcd7908635f4a15e4c4ae351f13f9aa393e56e67aca82e5ffd3cf5c463464ee7;
    }

    function nativeAttestationSchemaId() public pure override returns (bytes32 NATIVE_MACHINEHOOD_SCHEMA_ID) {
        // keccak256(bytes("uint8 platform, bytes deviceIdentity, bytes attData"))
        NATIVE_MACHINEHOOD_SCHEMA_ID = 0xb11541e7280d96b00370411a2ac95535280290a801f9de711a29a7abe16a68e0;
    }

    function getNativeAttestationFromDeviceIdentity(NativeAttestPlatform platform, bytes calldata deviceIdentity)
        public
        view
        override
        returns (bytes32 attestationId)
    {
        bytes32 index = keccak256(abi.encodePacked(uint8(platform), deviceIdentity));
        attestationId = nativeDeviceAttestations[index];
    }

    function getNativeAttestationStatus(NativeAttestPlatform platform, bytes calldata deviceIdentity)
        public
        view
        override
        returns (AttestationStatus status)
    {
        bytes32 index = keccak256(abi.encodePacked(uint8(platform), deviceIdentity));
        bytes32 attestationId = nativeDeviceAttestations[index];
        if (attestationId != bytes32(0)) {
            Attestation memory attestation = attestationRegistry.getAttestation(attestationId);
            if (attestation.revoked) {
                status = AttestationStatus.REVOKED;
            } else if (block.timestamp > attestation.expirationDate) {
                status = AttestationStatus.EXPIRED;
            } else {
                status = AttestationStatus.REGISTERED;
            }
        }
    }

    function _platformMapToWebAuthNverifier(WebAuthNAttestPlatform platform)
        internal
        view
        override
        returns (address verifier)
    {
        verifier = webAuthNVerifiers[platform];
    }

    function _platformMapToNativeVerifier(NativeAttestPlatform platform)
        internal
        view
        override
        returns (address verifier)
    {
        verifier = nativeVerifiers[platform];
    }

    function _attestWebAuthn(WebAuthNAttestationSchema memory att)
        internal
        override
        lock
        returns (bytes32 attestationId)
    {
        uint256 key = uint256(att.proofHash);
        if (proofBitmap.get(key)) {
            revert Attestation_Already_Exists();
        }

        // replay protection
        proofBitmap.set(key);

        bytes[] memory empty = new bytes[](0);

        AttestationPayload memory attestationPayload = AttestationPayload(
            webAuthNAttestationSchemaId(),
            0, // does it expire?
            abi.encodePacked(att.walletAddress),
            abi.encodePacked(att.proofHash)
        );

        attestationId = _getAttestationId();
        super.attest(attestationPayload, empty);
    }

    function _attestNative(NativeAttestationSchema memory att, uint256 expiry)
        internal
        override
        lock
        returns (bytes32 attestationId)
    {
        bytes32 index = keccak256(abi.encodePacked(att.platform, att.deviceIdentity));

        bytes[] memory empty = new bytes[](0);

        AttestationPayload memory attestationPayload = AttestationPayload(
            nativeAttestationSchemaId(),
            uint64(expiry),
            abi.encode(att.platform, att.deviceIdentity), // assign the device identity as the subject of this attestation
            att.attData
        );

        if (nativeDeviceAttestations[index] == bytes32(0)) {
            attestationId = _getAttestationId();
            super.attest(attestationPayload, empty);
            nativeDeviceAttestations[index] = attestationId;
        } else {
            revert Attestation_Already_Exists();
        }
    }

    function _getAttestationId() private view returns (bytes32 attestationId) {
        uint32 attestationIdCounter = attestationRegistry.getAttestationIdCounter() + 1;
        uint256 chainPrefix = attestationRegistry.getChainPrefix();
        attestationId = bytes32(abi.encode(chainPrefix + attestationIdCounter));
    }

    /// these methods are inherited simply to prevent users from invoking the default attest() method
    /// by guarding with the locked() modifier

    function _onAttest(AttestationPayload memory attestationPayload, address attester, uint256 value)
        internal
        override
        locked
    {}

    function _onReplace(
        bytes32 attestationId,
        AttestationPayload memory attestationPayload,
        address attester,
        uint256 value
    ) internal override locked {}

    function _onBulkAttest(AttestationPayload[] memory attestationsPayloads, bytes[][] memory validationPayloads)
        internal
        override
        locked
    {}

    function _onBulkReplace(
        bytes32[] memory attestationIds,
        AttestationPayload[] memory attestationsPayloads,
        bytes[][] memory validationPayloads
    ) internal override locked {}
}
