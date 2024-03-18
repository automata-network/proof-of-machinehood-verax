// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {SchemaRegistry} from "verax-contracts/SchemaRegistry.sol";
import {PortalRegistry} from "verax-contracts/PortalRegistry.sol";
import {ModuleRegistry} from "verax-contracts/ModuleRegistry.sol";
import {AttestationRegistry} from "verax-contracts/AttestationRegistry.sol";
import {MachinehoodEntrypointPortal} from "../src/MachinehoodEntrypointPortal.sol";

contract VeraxConfigurationScript is Script {
    PortalRegistry internal portalRegistry = PortalRegistry(vm.envAddress("PORTAL_REGISTRY_ADDRESS"));
    SchemaRegistry internal schemaRegistry = SchemaRegistry(vm.envAddress("SCHEMA_REGISTRY_ADDRESS"));
    ModuleRegistry internal moduleRegistry = ModuleRegistry(vm.envAddress("MODULE_REGISTRY_ADDRESS"));
    AttestationRegistry internal attestationRegistry =
        AttestationRegistry(vm.envAddress("ATTESTATION_REGISTRY_ADDRESS"));
    MachinehoodEntrypointPortal internal portal =
        MachinehoodEntrypointPortal(vm.envAddress("MACHINEHOOD_PORTAL_ADDRESS"));

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        // registers WebAuthN schema
        schemaRegistry.createSchema(
            "Proof of Machinehood Attestation",
            "https://docs.ata.network/automata-2.0/proof-of-machinehood",
            "",
            "bytes32 walletAddress, uint8 deviceType, bytes32 proofHash"
        );

        // registers NativeAttestation Schema
        schemaRegistry.createSchema(
            "Proof of Machinehood Native Attestation",
            "https://docs.ata.network/automata-2.0/proof-of-machinehood",
            "",
            "uint8 platform, bytes deviceIdentity, bytes attData"
        );

        // registers portal
        portalRegistry.register(
            address(portal),
            "Automata PoM Portal",
            "https://docs.ata.network/automata-2.0/proof-of-machinehood",
            false, // not-revocable
            "Automata Network"
        );
        vm.stopBroadcast();
    }
}
