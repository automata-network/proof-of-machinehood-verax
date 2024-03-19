// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {
    AndroidNative,
    BasicAttestationObject,
    SecurityLevel
} from "@automata-network/proof-of-machinehood-contracts/native/AndroidNative.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract AndroidNativeVerax is AndroidNative, Ownable {
    struct AttestationConfiguration {
        uint256 attestationVersion;
        SecurityLevel securityLevel;
        string packageName;
        uint256 packageVersion;
        bytes packageSignature;
    }

    AttestationConfiguration public config;

    mapping(uint256 => bool) _serialNumRevoked;

    constructor(address _sigVerifyLib) AndroidNative(_sigVerifyLib) {
        _initializeOwner(msg.sender);
    }

    function setConfig(AttestationConfiguration calldata newConfig) external onlyOwner {
        config = newConfig;
    }

    function revokeCertBatch(uint256[] calldata serialNums) external onlyOwner {
        for (uint256 i = 0; i < serialNums.length; i++) {
            if (!_serialNumRevoked[serialNums[i]]) {
                _revokeCert(serialNums[i], true);
            }
        }
    }

    function setSingleCertRevocationStatus(uint256 serialNum, bool revoked) external onlyOwner {
        _revokeCert(serialNum, revoked);
    }

    function certIsRevoked(uint256 serialNum) public view override returns (bool) {
        return _serialNumRevoked[serialNum];
    }

    function _validateAttestation(BasicAttestationObject memory att) internal view override returns (bool) {
        return (
            att.attestationVersion == config.attestationVersion
                && uint8(att.securityLevel) == uint8(config.securityLevel) && att.packageVersion == config.packageVersion
                && keccak256(bytes(att.packageName)) == keccak256(bytes(config.packageName))
                && keccak256(att.packageSignature) == keccak256(config.packageSignature)
        );
    }

    function _revokeCert(uint256 serialNum, bool revoked) private {
        _serialNumRevoked[serialNum] = revoked;
    }
}
