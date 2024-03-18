// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {MachinehoodEntrypointPortal, WebAuthNAttestPlatform} from "../src/MachinehoodEntrypointPortal.sol";

contract DeployMachinehoodEntrypointPortalScript is Script {
    MachinehoodEntrypointPortal portal;
    uint256 deployerKey = vm.envUint("PRIVATE_KEY");

    function deployPortal() public {
        vm.startBroadcast(deployerKey);

        address router = vm.envAddress("ROUTER_ADDRESS");
        address[] memory modules = new address[](0);

        portal = new MachinehoodEntrypointPortal(modules, router);

        vm.stopBroadcast();
    }

    function configureWebAuthNLib() public {
        vm.startBroadcast(deployerKey);

        address[3] memory webAuthnLib =
            [vm.envAddress("ANDROID_SAFETY_NET"), vm.envAddress("WINDOWS_TPM"), vm.envAddress("YUBIKEY")];

        portal = MachinehoodEntrypointPortal(vm.envAddress("MACHINEHOOD_PORTAL_ADDRESS"));

        for (uint256 i = 0; i < 3; i++) {
            portal.configureWebAuthNLib(WebAuthNAttestPlatform(uint8(i + 1)), webAuthnLib[i]);
        }

        vm.stopBroadcast();
    }
}
