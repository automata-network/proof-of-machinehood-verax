// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {SchemaRegistry} from "verax-contracts/SchemaRegistry.sol";
import {PortalRegistry} from "verax-contracts/PortalRegistry.sol";
import {ModuleRegistry} from "verax-contracts/ModuleRegistry.sol";
import {AttestationRegistry} from "verax-contracts/AttestationRegistry.sol";

import {SigVerifyLib} from "@automata-network/proof-of-machinehood-contracts/utils/SigVerifyLib.sol";
import {DerParser} from "@automata-network/proof-of-machinehood-contracts/utils/DerParser.sol";

import "../src/MachinehoodEntrypointPortal.sol";

abstract contract BaseTest is Test {
    address internal constant registryOwner = 0x39241A22eA7162C206409aAA2E4a56f9a79c15AB;
    address internal constant admin = 0x95d06B395F04dc1bBD0CE9fcC501D7044ea25DAd;
    string internal forkUrl = vm.envString("RPC_URL");
    address internal router = vm.envAddress("ROUTER_ADDRESS");
    PortalRegistry internal portalRegistry = PortalRegistry(vm.envAddress("PORTAL_REGISTRY_ADDRESS"));
    SchemaRegistry internal schemaRegistry = SchemaRegistry(vm.envAddress("SCHEMA_REGISTRY_ADDRESS"));
    ModuleRegistry internal moduleRegistry = ModuleRegistry(vm.envAddress("MODULE_REGISTRY_ADDRESS"));
    AttestationRegistry internal attestationRegistry =
        AttestationRegistry(vm.envAddress("ATTESTATION_REGISTRY_ADDRESS"));

    SigVerifyLib sigVerify;
    DerParser derParser;

    MachinehoodEntrypointPortal internal portal;

    function setUp() public virtual {
        uint256 fork = vm.createFork(forkUrl);
        vm.selectFork(fork);

        sigVerify = new SigVerifyLib();
        derParser = new DerParser();

        // adds admin as the issuer
        vm.prank(registryOwner);
        portalRegistry.setIssuer(admin);

        vm.startPrank(admin);

        // // registers the schema
        // commented out because this has been done on mainnet
        // uncomment this if the tests are running on a different fork
        // schemaRegistry.createSchema(
        //     "Proof of Machinehood Attestation",
        //     "https://docs.ata.network/automata-2.0/proof-of-machinehood",
        //     "",
        //     "bytes32 walletAddress, uint8 deviceType, bytes32 proofHash"
        // );

        // deploys portal
        address[] memory modules = new address[](0);

        portal = new MachinehoodEntrypointPortal(modules, router);

        portalRegistry.register(
            address(portal),
            "MachinehoodEntrypointPortal",
            "portal-description",
            false, // not-revocable
            "portal-owner-name"
        );

        vm.stopPrank();
    }

    function testSetup() public {
        assertTrue(portalRegistry.isIssuer(admin));
        assertTrue(schemaRegistry.isRegistered(portal.webAuthNAttestationSchemaId()));
        assertTrue(portalRegistry.isRegistered(address(portal)));
    }
}
