// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AndroidSafetyNet} from "@automata-network/proof-of-machinehood-contracts/webauthn/AndroidSafetyNet.sol";

import "./BaseTest.t.sol";
import {AttestationPayload, Attestation} from "verax-contracts/types/Structs.sol";
import {AndroidSafetyNetConstants} from "./constants/AndroidSafetyNetConstants.t.sol";

contract AndroidSafetyNetTest is BaseTest, AndroidSafetyNetConstants {
    AndroidSafetyNet attestationContract;

    address constant user = 0xc6219fd7C54c963A7eF13e04eF0f0D96ff826450;

    function setUp() public override {
        super.setUp();

        // Bypass Expired Certificate reverts
        // October 10th, 2023, 4am GMT
        vm.warp(1696910400);

        vm.startPrank(admin);

        attestationContract = new AndroidSafetyNet(address(sigVerify), address(derParser));
        attestationContract.addCACert(certHash);

        portal.configureWebAuthNLib(WebAuthNAttestPlatform.ANDROID, address(attestationContract));

        vm.stopPrank();
    }

    function testAttest() public {
        bytes32 walletAddress = bytes32(uint256(uint160(user)));

        bytes32 attestationId = portal.webAuthNAttest(
            WebAuthNAttestPlatform.ANDROID,
            walletAddress,
            encodedAttStmt,
            authData,
            clientDataJSON
        );
        assertTrue(attestationRegistry.isRegistered(attestationId));

        // replay attempt
        vm.expectRevert(MachinehoodEntrypointPortal.Attestation_Already_Exists.selector);
        portal.webAuthNAttest(
            WebAuthNAttestPlatform.ANDROID,
            walletAddress,
            encodedAttStmt,
            authData,
            clientDataJSON
        );
    }
}
