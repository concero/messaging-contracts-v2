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

contract WithdrawOperatorFee is ConceroVerifierTest {
    function setUp() public override {
        super.setUp();

        vm.deal(operator, 100 ether);
        bytes32 operatorKey = bytes32(uint256(uint160(operator)));
        vm.prank(deployer);
        conceroVerifier.setStorage(Namespaces.OPERATOR, OperatorSlots.isRegistered, operatorKey, 1);
        _setPriceFeeds();
    }

    function test_withdrawOperatorFee() public {
        _setOperatorFeesEarned();

        uint256 initialBalance = operator.balance;
        vm.deal(address(conceroVerifier), OPERATOR_FEES_NATIVE);

        vm.prank(operator);
        conceroVerifier.withdrawOperatorFee(OPERATOR_FEES_NATIVE);

        assertEq(conceroVerifier.getOperatorFeesEarned(operator), 0, "Fees not cleared");
        assertEq(operator.balance, initialBalance + OPERATOR_FEES_NATIVE, "Balance mismatch");
    }

    function test_withdrawOperatorFee_WhenAmountZero_Reverts() public {
        vm.prank(operator);
        vm.expectRevert(CommonErrors.InvalidAmount.selector);
        conceroVerifier.withdrawOperatorFee(0);
    }

    function test_withdrawOperatorFee_WhenInsufficientBalance_Reverts() public {
        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.InsufficientFee.selector, OPERATOR_FEES_NATIVE, 0)
        );
        conceroVerifier.withdrawOperatorFee(OPERATOR_FEES_NATIVE);
    }
}
