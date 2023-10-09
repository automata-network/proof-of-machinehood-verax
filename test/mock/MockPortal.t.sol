// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DefaultPortal} from "verax-contracts/portal/DefaultPortal.sol";

contract MockPortal is DefaultPortal {
    constructor(address[] memory modules, address router) DefaultPortal(modules, router) {}
}