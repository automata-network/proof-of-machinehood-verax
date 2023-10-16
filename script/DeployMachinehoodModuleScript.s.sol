// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {MachinehoodModule} from "../src/MachinehoodModule.sol";

contract DeployMachinehoodModuleScript is Script {
    MachinehoodModule module;

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        module = new MachinehoodModule();

        vm.stopBroadcast();
    }
}
