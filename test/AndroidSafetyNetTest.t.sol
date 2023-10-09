// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BaseTest.t.sol";
import {AttestationPayload, Attestation} from "verax-contracts/types/Structs.sol";
import {AndroidSafetyNet} from "../src/lib/verification/AndroidSafetyNet.sol";
import {AndroidSafetyNetConstants} from "./constants/AndroidSafetyNetConstants.t.sol";
import {SigVerifyLib} from "../src/lib/utils/SigVerifyLib.sol";
import {DerParser} from "../src/lib/utils/DerParser.sol";

contract AndroidSafetyNetTest is BaseTest, AndroidSafetyNetConstants {

    SigVerifyLib sigVerify;
    DerParser derParser;
    AndroidSafetyNet attestationContract;

    address constant user = address(2);

    function setUp() public override {
        super.setUp();

        vm.startPrank(admin);

        sigVerify = new SigVerifyLib();
        derParser = new DerParser();

        attestationContract = new AndroidSafetyNet(address(sigVerify), address(derParser));
        attestationContract.addCACert(certHash);

        module.configureSupportedDevice(MachinehoodModule.DeviceType.ANDROID, address(attestationContract));

        vm.stopPrank();
    }

    function testAttest() public {
        bytes32 walletAddress = bytes32(uint256(uint160(user)));

        MachinehoodModule.ValidationPayloadStruct memory validationPayload = MachinehoodModule.ValidationPayloadStruct({
            attStmt: encodedAttStmt,
            authData: authData,
            clientData: clientDataJSON
        });

        bytes memory encodedValidationData = abi.encode(validationPayload);

        bytes memory attestationData = abi.encode(
            walletAddress,
            uint8(1),
            keccak256(encodedValidationData)
        );

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
    }


}