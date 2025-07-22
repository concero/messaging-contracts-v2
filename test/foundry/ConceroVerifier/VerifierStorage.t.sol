// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {GenericStorage} from "contracts/common/libraries/GenericStorage.sol";

import {VerifierSlots, OperatorSlots} from "contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {Storage as s, Namespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";

import {ConceroVerifierTest} from "./base/ConceroVerifierTest.sol";

contract VerifierStorage is ConceroVerifierTest {
    function setUp() public override {
        super.setUp();
    }

    function test_SetAndGetNonce() public {
        uint256 newNonce = 123;

        vm.startPrank(deployer);
        conceroVerifier.setStorage(Namespaces.VERIFIER, VerifierSlots.nonce, bytes32(0), newNonce);

        assertEq(
            conceroVerifier.getStorage(Namespaces.VERIFIER, VerifierSlots.nonce, bytes32(0)),
            newNonce,
            "Storage getter failed for nonce"
        );
        vm.stopPrank();
    }

    function test_SetAndGetTotalFeesEarned() public {
        uint256 newFees = 1000;

        vm.startPrank(deployer);
        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0),
            newFees
        );

        assertEq(
            conceroVerifier.getStorage(
                Namespaces.OPERATOR,
                OperatorSlots.totalFeesEarnedNative,
                bytes32(0)
            ),
            newFees,
            "Storage getter failed for totalFeesEarnedNative"
        );
        vm.stopPrank();
    }

    function test_SetAndGetOperatorIsRegistered() public {
        address operator = address(0x123);
        bool isRegistered = true;

        vm.startPrank(deployer);
        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.isRegistered,
            bytes32(uint256(uint160(operator))),
            isRegistered ? 1 : 0
        );

        assertEq(
            conceroVerifier.getStorage(
                Namespaces.OPERATOR,
                OperatorSlots.isRegistered,
                bytes32(uint256(uint160(operator)))
            ),
            isRegistered ? 1 : 0,
            "Storage getter failed for isRegistered"
        );
        vm.stopPrank();
    }

    function test_SetStorageBulk() public {
        address[] memory operators = new address[](2);
        operators[0] = address(0x123);
        operators[1] = address(0x456);

        uint256[] memory deposits = new uint256[](2);
        deposits[0] = 1000;
        deposits[1] = 2000;

        bytes32[] memory namespaces = new bytes32[](2);
        uint256[] memory offsets = new uint256[](2);
        bytes32[] memory mappingKeys = new bytes32[](2);
        uint256[] memory values = new uint256[](2);

        for (uint256 i = 0; i < 2; i++) {
            namespaces[i] = Namespaces.OPERATOR;
            offsets[i] = OperatorSlots.depositsNative;
            mappingKeys[i] = bytes32(uint256(uint160(operators[i])));
            values[i] = deposits[i];
        }

        vm.startPrank(deployer);
        conceroVerifier.setStorageBulk(namespaces, offsets, mappingKeys, values);

        for (uint256 i = 0; i < 2; i++) {
            assertEq(
                conceroVerifier.getStorage(
                    Namespaces.OPERATOR,
                    OperatorSlots.depositsNative,
                    mappingKeys[i]
                ),
                deposits[i],
                "Bulk storage update failed"
            );
        }
        vm.stopPrank();
    }

    function test_RevertInvalidStorageSlot() public {
        vm.expectRevert(GenericStorage.InvalidNamespace.selector);

        bytes32 invalidNamespace = keccak256("invalid.namespace");

        vm.prank(deployer);
        conceroVerifier.setStorage(invalidNamespace, 0, bytes32(0), 1);
    }

    function test_RevertLengthMismatch() public {
        bytes32[] memory namespaces = new bytes32[](2);
        uint256[] memory offsets = new uint256[](2);
        bytes32[] memory mappingKeys = new bytes32[](1);
        uint256[] memory values = new uint256[](2);

        namespaces[0] = Namespaces.OPERATOR;
        namespaces[1] = Namespaces.VERIFIER;

        vm.expectRevert(CommonErrors.LengthMismatch.selector);

        vm.prank(deployer);
        conceroVerifier.setStorageBulk(namespaces, offsets, mappingKeys, values);
    }

    function test_SetAndGetPendingCLFRequest() public {
        bytes32 requestId = keccak256("request123");
        bool isPending = true;

        vm.startPrank(deployer);
        conceroVerifier.setStorage(
            Namespaces.VERIFIER,
            VerifierSlots.pendingCLFRequests,
            requestId,
            isPending ? 1 : 0
        );

        assertEq(
            conceroVerifier.getStorage(
                Namespaces.VERIFIER,
                VerifierSlots.pendingCLFRequests,
                requestId
            ),
            isPending ? 1 : 0,
            "Pending CLF request status not set"
        );
        vm.stopPrank();
    }
}
