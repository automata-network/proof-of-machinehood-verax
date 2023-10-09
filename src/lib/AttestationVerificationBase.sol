// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract AttestationVerificationBase {
    function verifyAttStmt(bytes memory attStmt, bytes memory authData, bytes memory clientData) external virtual;
}
