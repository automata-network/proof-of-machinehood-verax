// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {DefaultPortal} from "verax-contracts/DefaultPortal.sol";
import {Ownable} from "solady/Milady.sol";

/**
 * @notice This is a custom Portal made to allow re-configuration of modules.
 */

contract MachinehoodPortal is DefaultPortal, Ownable {
    constructor(address[] memory modules, address router) DefaultPortal(modules, router) {
        _initializeOwner(msg.sender);
    }

    function resetModules(address[] calldata newModules) external onlyOwner {
        modules = newModules;
    }
}
