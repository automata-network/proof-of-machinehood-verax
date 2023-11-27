// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {SchemaRegistry} from "verax-contracts/SchemaRegistry.sol";
import {PortalRegistry} from "verax-contracts/PortalRegistry.sol";
import {ModuleRegistry} from "verax-contracts/ModuleRegistry.sol";
import {AttestationRegistry} from "verax-contracts/AttestationRegistry.sol";
import {MachinehoodPortal} from "../src/MachinehoodPortal.sol";
import {MachinehoodModule} from "../src/MachinehoodModule.sol";

contract VeraxConfigurationScript is Script {
    PortalRegistry internal portalRegistry = PortalRegistry(vm.envAddress("PORTAL_REGISTRY_ADDRESS"));
    SchemaRegistry internal schemaRegistry = SchemaRegistry(vm.envAddress("SCHEMA_REGISTRY_ADDRESS"));
    ModuleRegistry internal moduleRegistry = ModuleRegistry(vm.envAddress("MODULE_REGISTRY_ADDRESS"));
    AttestationRegistry internal attestationRegistry =
        AttestationRegistry(vm.envAddress("ATTESTATION_REGISTRY_ADDRESS"));
    MachinehoodModule internal module = MachinehoodModule(vm.envAddress("MACHINEHOOD_MODULE_ADDRESS"));
    MachinehoodPortal internal portal = MachinehoodPortal(vm.envAddress("MACHINEHOOD_PORTAL_ADDRESS"));

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        // registers the schema
        schemaRegistry.createSchema(
            "Machinehood Attestation",
            "https://docs.ata.network/automata-2.0/proof-of-machinehood",
            "",
            "bytes32 walletAddress, uint8 deviceType, bytes32 proofHash"
        );

        // registers module
        moduleRegistry.register(
            "MachinehoodModule", "https://docs.ata.network/automata-2.0/proof-of-machinehood", address(module)
        );

        // registers portal
        portalRegistry.register(
            address(portal),
            "MachinehoodPortal (Test)",
            "This is a test portal for Machinehood Attestation",
            false, // not-revocable
            "test-owner"
        );
        vm.stopBroadcast();
    }
}
