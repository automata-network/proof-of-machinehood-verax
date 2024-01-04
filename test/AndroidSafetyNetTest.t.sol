// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AndroidSafetyNet} from "@automata-network/proof-of-machinehood-contracts/AndroidSafetyNet.sol";

import "./BaseTest.t.sol";
import {AttestationPayload, Attestation} from "verax-contracts/types/Structs.sol";
import {MachinehoodModule} from "../src/MachinehoodModule.sol";
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

        module.configureSupportedDevice(DeviceType.ANDROID, address(attestationContract));

        vm.stopPrank();
    }

    function testAttest() public {
        bytes32 walletAddress = bytes32(uint256(uint160(user)));

        ValidationPayloadStruct memory validationPayload =
            ValidationPayloadStruct({attStmt: encodedAttStmt, authData: authData, clientData: clientDataJSON});

        bytes memory encodedValidationData = abi.encode(validationPayload);

        bytes memory attestationData = abi.encode(walletAddress, uint8(1), keccak256(encodedValidationData));

        bytes[] memory validationPayloadArr = new bytes[](1);
        validationPayloadArr[0] = encodedValidationData;

        AttestationPayload memory attestationPayload = AttestationPayload({
            schemaId: module.MACHINEHOOD_SCHEMA_ID(),
            expirationDate: 0,
            subject: bytes("test-subject"),
            attestationData: attestationData
        });

        uint32 counter = attestationRegistry.getAttestationIdCounter();
        bytes32 id = bytes32(abi.encode(++counter));

        portal.attest(attestationPayload, validationPayloadArr);
        assertTrue(attestationRegistry.isRegistered(id));

        // replay attempt
        vm.expectRevert(MachinehoodModule.Duplicate_Proof_Hash_Found.selector);
        portal.attest(attestationPayload, validationPayloadArr);
    }
}
