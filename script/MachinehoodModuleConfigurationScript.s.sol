// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {MachinehoodModule, DeviceType} from "../src/MachinehoodModule.sol";

contract MachinehoodModuleConfigurationScript is Script {
    MachinehoodModule module = MachinehoodModule(vm.envAddress("MACHINEHOOD_MODULE_ADDRESS"));
    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        address[3] memory lib =[
            vm.envAddress("ANDROID_SAFETY_NET"),
            vm.envAddress("WINDOWS_TPM"),
            vm.envAddress("YUBIKEY")
        ];

        vm.startBroadcast(privateKey);

        for (uint256 i = 0; i < 3; i++) {
            module.configureSupportedDevice(DeviceType(uint8(i + 1)), lib[i]);
        }

        vm.stopBroadcast();
    }
}