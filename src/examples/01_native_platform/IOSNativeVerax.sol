// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IOSNative, IOSPayload, IOSAssertionPayload} from "@automata-network/proof-of-machinehood-contracts/native/IOSNative.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract IOSNativeVerax is IOSNative, Ownable {
    
    /// === aaguid constants ===

    // bytes("appattestdevelop")
    bytes16 constant DEVELOPMENT_AAGUID = 0x617070617474657374646576656c6f70;
    // bytes("appattest") followed by 7 0x0 bytes
    bytes16 constant PRODUCTION_AAGUID = 0x61707061747465737400000000000000;

    bytes32 _appIdHash;

    constructor(address _sigVerifyLib, bytes32 _appId) IOSNative(_sigVerifyLib) {
        _initializeOwner(msg.sender);
        _appIdHash = _appId;
    }

    function setAppIdHash(bytes32 id) external onlyOwner {
        _appIdHash = id;
    }

    function appIdHash() public view override returns (bytes32) {
        return _appIdHash;
    }

    /// @dev configure the validity of the operating environment
    /// either "appattestdevelop" or "appattest" followed by 7 0x00 bytes
    /// the default behavior accepts both envrionments
    function _aaguidIsValid(bytes16 aaguid) internal pure override returns (bool) {
        return aaguid == DEVELOPMENT_AAGUID || aaguid == PRODUCTION_AAGUID;
    }
}