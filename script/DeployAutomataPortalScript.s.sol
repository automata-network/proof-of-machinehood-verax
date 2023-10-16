// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {AutomataPortal} from "../src/AutomataPortal.sol";

contract DeployAutomataPortalScript is Script {
    AutomataPortal portal;

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        address router = vm.envAddress("ROUTER_ADDRESS");
        address[] memory modules = new address[](1);
        modules[0] = vm.envAddress("MACHINEHOOD_MODULE_ADDRESS");

        portal = new AutomataPortal(
            modules,
            router
        );

        vm.stopBroadcast();
    }
}
