// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {SchemaRegistry} from "verax-contracts/SchemaRegistry.sol";
import {PortalRegistry} from "verax-contracts/PortalRegistry.sol";
import {ModuleRegistry} from "verax-contracts/ModuleRegistry.sol";
import {AttestationRegistry} from "verax-contracts/AttestationRegistry.sol";

import {AutomataPortal} from "../src/AutomataPortal.sol";
import {MachinehoodModule} from "../src/MachinehoodModule.sol";

abstract contract BaseTest is Test {
    address internal constant registryOwner = 0x809e815596AbEB3764aBf81BE2DC39fBBAcc9949;
    address internal constant admin = 0x95d06B395F04dc1bBD0CE9fcC501D7044ea25DAd;
    string internal forkUrl = vm.envString("RPC_URL");
    address internal router = vm.envAddress("ROUTER_ADDRESS");
    PortalRegistry internal portalRegistry = PortalRegistry(vm.envAddress("PORTAL_REGISTRY_ADDRESS"));
    SchemaRegistry internal schemaRegistry = SchemaRegistry(vm.envAddress("SCHEMA_REGISTRY_ADDRESS"));
    ModuleRegistry internal moduleRegistry = ModuleRegistry(vm.envAddress("MODULE_REGISTRY_ADDRESS"));
    AttestationRegistry internal attestationRegistry =
        AttestationRegistry(vm.envAddress("ATTESTATION_REGISTRY_ADDRESS"));
    MachinehoodModule internal module = MachinehoodModule(vm.envAddress("MACHINEHOOD_MODULE_ADDRESS"));
    AutomataPortal internal portal = AutomataPortal(vm.envAddress("AUTOMATA_PORTAL_ADDRESS"));

    function setUp() public virtual {
        uint256 fork = vm.createFork(forkUrl);
        vm.selectFork(fork);

        // // adds admin as the issuer
        // vm.prank(registryOwner);
        // portalRegistry.setIssuer(admin);

        // vm.startPrank(admin);

        // // registers the schema
        // schemaRegistry.createSchema(
        //     "Machinehood Attestation",
        //     "https://docs.ata.network/automata-2.0/proof-of-machinehood",
        //     "",
        //     "bytes32 walletAddress, uint8 deviceType, bytes32 proofHash"
        // );

        // // deploys the module
        // module = new MachinehoodModule();

        // // registers module
        // moduleRegistry.register("MachinehoodModule", "module-description", address(module));

        // // deploys portal
        // address[] memory modules = new address[](1);
        // modules[0] = address(module);

        // portal = new AutomataPortal(modules, router);

        // portalRegistry.register(
        //     address(portal),
        //     "MachinehoodPortal",
        //     "portal-description",
        //     false, // not-revocable
        //     "portal-owner-name"
        // );

        // vm.stopPrank();
    }

    function testSetup() public {
        // assertTrue(portalRegistry.isIssuer(admin));
        assertTrue(schemaRegistry.isRegistered(module.MACHINEHOOD_SCHEMA_ID()));
        assertTrue(moduleRegistry.isRegistered(address(module)));
        assertTrue(portalRegistry.isRegistered(address(portal)));
    }
}
