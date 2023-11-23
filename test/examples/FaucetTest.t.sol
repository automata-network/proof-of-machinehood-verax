// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AndroidSafetyNet} from "@automata-network/machinehood-contracts/AndroidSafetyNet.sol";
import {AttestationPayload, Attestation} from "verax-contracts/types/Structs.sol";

import "../BaseTest.t.sol";
import {AndroidSafetyNetConstants} from "../constants/AndroidSafetyNetConstants.t.sol";

import {Faucet, DeviceType} from "../../src/examples/00_faucet/Faucet.sol";
import {MockERC20} from "../../src/examples/00_faucet/MockERC20.sol";

/**
 * @title Unit tests on the example Faucet contract with Android Safety Net attestation
 */

contract FaucetTest is BaseTest, AndroidSafetyNetConstants {
    AndroidSafetyNet attestationContract;
    Faucet faucet;
    MockERC20 mockToken;

    address constant user = 0xc6219fd7C54c963A7eF13e04eF0f0D96ff826450;

    // Bypass Expired Certificate reverts
    // October 10th, 2023, 4am GMT
    uint256 beginningTimestamp = 1696910400;

    // attestation only lasts for a day
    uint256 duration = 3600 * 24;

    event AttestationRegistered(bytes32 indexed attestationId);

    function setUp() public override {
        super.setUp();

        vm.warp(beginningTimestamp);

        vm.startPrank(admin);

        attestationContract = new AndroidSafetyNet(address(sigVerify), address(derParser));
        attestationContract.addCACert(certHash);
        module.configureSupportedDevice(DeviceType.ANDROID, address(attestationContract));

        mockToken = new MockERC20();
        faucet = new Faucet(
            address(attestationRegistry),
            address(portal),
            address(module),
            address(mockToken)
        );

        faucet.setAttestationValidityDuration(duration);

        vm.stopPrank();
    }

    function testFaucetConfiguration() public {
        assertEq(faucet.attestationValidityDurationInSeconds(), duration);
        assertEq(address(faucet.attestationRegistry()), address(attestationRegistry));
        assertEq(address(faucet.portal()), address(portal));
        assertEq(address(faucet.module()), address(module));
        assertEq(address(faucet.token()), address(mockToken));
    }

    function testRequestBeforeAttesting() public {
        vm.expectRevert(Faucet.Attestation_Not_Registered.selector);
        faucet.requestTokens(user);
        assertEq(mockToken.balanceOf(user), 0);
    }

    /// @notice Fuzzed test. The attestation might expire if we warp too far into the future...
    function testAttestThenRequestTokens(uint256 warp) public {
        // check the AttestationRegistered event
        uint32 counter = attestationRegistry.getAttestationIdCounter();
        bytes32 id = bytes32(abi.encode(++counter));
        vm.expectEmit(true, false, false, false, address(attestationRegistry));
        emit AttestationRegistered(id);

        faucet.attest(user, DeviceType.ANDROID, authData, clientDataJSON, encodedAttStmt);
        assertTrue(attestationRegistry.isRegistered(id));
        assertTrue(faucet.attestationIsValid(user));

        uint256 expiry = block.timestamp + duration;
        warp = bound(warp, expiry - 3600, expiry + 3600);
        vm.warp(warp);

        bool expired = warp >= expiry;
        assertEq(faucet.attestationIsValid(user), !expired);
        if (expired) {
            vm.expectRevert(abi.encodeWithSelector(
                Faucet.Attestation_Expired.selector,
                id
            ));
        }

        faucet.requestTokens(user);
        uint256 expectedBalance = expired ? 0 : 0.1 ether; 
        assertEq(mockToken.balanceOf(user), expectedBalance);       
    }
}