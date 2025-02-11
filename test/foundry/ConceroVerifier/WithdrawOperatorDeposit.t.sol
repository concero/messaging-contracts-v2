// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {console} from "forge-std/src/Console.sol";
import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {Namespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";
import {Errors} from "contracts/ConceroVerifier/libraries/Errors.sol";
import {ConceroVerifierTest} from "./base/ConceroVerifierTest.sol";
import {OperatorSlots, PriceFeedSlots} from "contracts/ConceroVerifier/libraries/StorageSlots.sol";

contract WithdrawOperatorDeposit is ConceroVerifierTest {
    function setUp() public override {
        super.setUp();

        vm.deal(operator, 100 ether);
        bytes32 operatorKey = bytes32(uint256(uint160(operator)));
        vm.prank(deployer);
        conceroVerifier.setStorage(Namespaces.OPERATOR, OperatorSlots.isAllowed, operatorKey, 1);
        _setPriceFeeds();
    }

    function test_OperatorDeposit() public {
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();

        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: minimumDeposit}(operator);

        assertEq(
            conceroVerifier.getOperatorDeposit(operator),
            minimumDeposit,
            "Operator deposit amount mismatch"
        );
    }

    function test_MultipleDeposits() public {
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();

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
        uint256 depositAmount = conceroVerifier.getCLFDeposit();
        uint256 withdrawAmount = depositAmount;

        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: depositAmount}(operator);

        uint256 preWithdrawBalance = operator.balance;

        vm.prank(operator);
        bool success = conceroVerifier.withdrawOperatorDeposit(withdrawAmount);

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
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();
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
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();
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
