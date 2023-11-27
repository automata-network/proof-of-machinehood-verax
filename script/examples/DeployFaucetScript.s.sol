// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Faucet} from "../../src/examples/00_faucet/Faucet.sol";
import {MockERC20} from "../../src/examples/00_faucet/MockERC20.sol";

contract DeployFaucetScript is Script {
    MockERC20 token;
    Faucet faucet;
    address machinehoodPortal = vm.envAddress("MACHINEHOOD_PORTAL_ADDRESS");
    address attestationRegistry = vm.envAddress("ATTESTATION_REGISTRY_ADDRESS");

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);
        token = new MockERC20();
        faucet = new Faucet(attestationRegistry, machinehoodPortal, address(token));
        vm.stopBroadcast();

        console.log("[LOG] MockToken deployed at: ", address(token));
        console.log("[LOG] Faucet deployed at: ", address(faucet));
    }
}