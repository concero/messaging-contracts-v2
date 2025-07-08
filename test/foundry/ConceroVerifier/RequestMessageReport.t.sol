// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/Console.sol";

import {CommonTypes} from "contracts/common/CommonTypes.sol";

import {Errors} from "contracts/ConceroVerifier/libraries/Errors.sol";
import {Message as MessageLib} from "contracts/common/libraries/Message.sol";
import {Namespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";
import {VerifierSlots} from "contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {Namespaces as VerifierNamespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";
import {OperatorSlots} from "contracts/ConceroVerifier/libraries/StorageSlots.sol";

import {ConceroVerifierTest} from "./base/ConceroVerifierTest.sol";

contract RequestMessageReport is ConceroVerifierTest {
    function setUp() public virtual override {
        super.setUp();

        _setPriceFeeds();
        _setOperatorDeposits();
        _setOperatorIsRegistered();
    }

    function test_requestMessageReport() public returns (bytes32) {
        bytes32 messageId = bytes32(uint256(1));
        bytes32 messageHashSum = bytes32(uint256(2));

        bytes memory srcChainData = new bytes(0);

        vm.prank(operator);
        bytes32 clfRequestId = conceroVerifier.requestMessageReport(
            messageId,
            messageHashSum,
            SRC_CHAIN_SELECTOR,
            srcChainData
        );

        bool isCLFRequestPending = conceroVerifier.getStorage(
            Namespaces.VERIFIER,
            VerifierSlots.pendingCLFRequests,
            clfRequestId
        ) == 1;

        assertTrue(isCLFRequestPending);

        return clfRequestId;
    }

    function test_requestMessageReport_RevertsIfInsufficientOperatorDeposit() public {
        bytes32 messageId = bytes32(uint256(1));
        bytes32 messageHashSum = bytes32(uint256(2));

        bytes memory srcChainData = new bytes(0);

        // clean the storage
        vm.prank(deployer);
        conceroVerifier.setStorage(
            VerifierNamespaces.OPERATOR,
            OperatorSlots.depositsNative,
            bytes32(uint256(uint160(operator))),
            0
        );

        uint256 depositAmount = conceroVerifier.getCLFCost();
        vm.deal(address(operator), depositAmount);

        vm.startPrank(operator);
        // deposit funds to the verifier
        conceroVerifier.operatorDeposit{value: depositAmount}(address(operator));

        // withdraw funds from the verifier
        conceroVerifier.withdrawOperatorDeposit(depositAmount);
        uint256 currentDeposit = conceroVerifier.getOperatorDeposit(operator);

        vm.expectRevert(abi.encodeWithSelector(Errors.InsufficientOperatorDeposit.selector, currentDeposit, depositAmount));

        // request message report
        conceroVerifier.requestMessageReport(
            messageId,
            messageHashSum,
            SRC_CHAIN_SELECTOR,
            srcChainData
        );
        vm.stopPrank();
    }
}
