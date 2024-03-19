// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {MacNative} from "@automata-network/proof-of-machinehood-contracts/native/MacNative.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract MacNativeVerax is MacNative, Ownable {
    
    mapping (address => bool) _authorizedKeys;

    constructor() {
        _initializeOwner(msg.sender);
    }

    function configureTrustedKey(address key, bool trusted) external onlyOwner {
        _authorizedKeys[key] = trusted;
    }

    function trustedSigningKey(address key) public view override returns (bool) {
        return _authorizedKeys[key];
    }
}