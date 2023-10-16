// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {AndroidSafetyNet} from "../src/lib/verification/AndroidSafetyNet.sol";

contract DeployAndroidSafetyNetScript is Script {

    AndroidSafetyNet attestation;

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        address sigVerify = vm.envAddress("SIGVERIFY_LIB");
        address derParser = vm.envAddress("DERPARSER_LIB");

        attestation = new AndroidSafetyNet(sigVerify, derParser);

        vm.stopBroadcast();
    }
}