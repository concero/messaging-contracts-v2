// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/Console.sol";

import {CommonErrors} from "contracts/common/CommonErrors.sol";

import {Namespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";
import {Errors} from "contracts/ConceroVerifier/libraries/Errors.sol";
import {OperatorSlots, PriceFeedSlots} from "contracts/ConceroVerifier/libraries/StorageSlots.sol";

import {ConceroVerifierTest} from "./base/ConceroVerifierTest.sol";

contract WithdrawOperatorDeposit is ConceroVerifierTest {
    function setUp() public override {
        super.setUp();

        vm.deal(operator, 100 ether);

        vm.prank(deployer);
        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.isRegistered,
            bytes32(uint256(uint160(operator))),
            1
        );

        _setPriceFeeds();
    }

    function test_OperatorDeposit() public {
        uint256 minimumDeposit = conceroVerifier.getCLFCost();

        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: minimumDeposit}(operator);

        assertEq(
            conceroVerifier.getOperatorDeposit(operator),
            minimumDeposit,
            "Operator deposit amount mismatch"
        );
    }

    function test_MultipleDeposits() public {
        uint256 minimumDeposit = conceroVerifier.getCLFCost();

        vm.startPrank(operator);
        conceroVerifier.operatorDeposit{value: minimumDeposit}(operator);
        conceroVerifier.operatorDeposit{value: minimumDeposit}(operator);

        assertEq(
            conceroVerifier.getOperatorDeposit(operator),
            minimumDeposit * 2,
            "Multiple deposits should accumulate correctly"
        );
        vm.stopPrank();
    }

    function test_WithdrawOperatorDeposit() public {
        uint256 depositAmount = conceroVerifier.getCLFCost();
        uint256 withdrawAmount = depositAmount;

        vm.startPrank(operator);
        conceroVerifier.operatorDeposit{value: depositAmount}(operator);
        uint256 preWithdrawBalance = operator.balance;
        bool success = conceroVerifier.withdrawOperatorDeposit(withdrawAmount);
        vm.stopPrank();

        assertTrue(success, "Withdrawal should succeed");

        assertEq(
            conceroVerifier.getOperatorDeposit(operator),
            depositAmount - withdrawAmount,
            "Remaining deposit amount mismatch"
        );

        assertEq(operator.balance, preWithdrawBalance + withdrawAmount, "Balance change mismatch");
    }

    function test_withdrawOperatorDeposit_WhenAmountZero_Reverts() public {
        vm.prank(operator);
        vm.expectRevert(CommonErrors.InvalidAmount.selector);
        conceroVerifier.withdrawOperatorDeposit(0);
    }

    function test_withdrawOperatorDeposit_WhenAmountExceedsDeposit_Reverts() public {
        uint256 minimumDeposit = conceroVerifier.getCLFCost();
        uint256 depositAmount = minimumDeposit;
        uint256 withdrawAmount = depositAmount + 1 ether;

        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: depositAmount}(operator);

        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InsufficientOperatorDeposit.selector,
                depositAmount,
                withdrawAmount
            )
        );
        conceroVerifier.withdrawOperatorDeposit(withdrawAmount);
    }

    function test_withdrawOperatorDeposit_WhenAmountBelowMinimum_Reverts() public {
        uint256 minimumDeposit = conceroVerifier.getCLFCost();
        uint256 depositAmount = minimumDeposit;
        uint256 withdrawAmount = depositAmount + 1;

        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: depositAmount}(operator);

        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InsufficientOperatorDeposit.selector,
                depositAmount,
                withdrawAmount
            )
        );
        conceroVerifier.withdrawOperatorDeposit(withdrawAmount);
    }
}
