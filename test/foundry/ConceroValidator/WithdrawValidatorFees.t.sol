// SPDX-License-Identifier: UNLICENSED
/* solhint-disable func-name-mixedcase */
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Errors} from "contracts/ConceroValidator/libraries/Errors.sol";
import {CommonErrors} from "contracts/common/CommonErrors.sol";

import {ConceroValidatorTest} from "./base/ConceroValidatorTest.sol";

contract WithdrawValidatorFeesTest is ConceroValidatorTest {
    function setUp() public override {
        super.setUp();
    }

    function test_withdrawValidatorFee() public {
        uint256 depositAmount = s_conceroValidator.getMinimumDeposit();
        _deposit(depositAmount);

        bytes32 messageId = bytes32(uint256(1));
        bytes memory srcChainData = new bytes(0);

        vm.prank(s_relayer);
        s_conceroValidator.requestMessageReport(messageId, SRC_CHAIN_SELECTOR, srcChainData);

        assertEq(s_conceroValidator.getWithdrawableValidatorFee(), depositAmount);

        uint256 ownerBalanceBefore = s_deployer.balance;

		vm.prank(s_deployer);
        s_conceroValidator.withdrawValidatorFee(depositAmount);

        assertEq(s_deployer.balance, ownerBalanceBefore + depositAmount);
        assertEq(s_conceroValidator.getWithdrawableValidatorFee(), 0);
        assertEq(address(s_conceroValidator).balance, 0);
    }

    function test_withdrawValidatorFee_partial() public {
        uint256 depositAmount = s_conceroValidator.getMinimumDeposit() * 2;
        _deposit(depositAmount);

        bytes32 messageId1 = bytes32(uint256(1));
        bytes32 messageId2 = bytes32(uint256(2));
        bytes memory srcChainData = new bytes(0);

        vm.startPrank(s_relayer);
        s_conceroValidator.requestMessageReport(messageId1, SRC_CHAIN_SELECTOR, srcChainData);
        s_conceroValidator.requestMessageReport(messageId2, SRC_CHAIN_SELECTOR, srcChainData);
        vm.stopPrank();

        uint256 totalFees = depositAmount;
        uint256 withdrawAmount = totalFees / 2;

		vm.prank(s_deployer);
        s_conceroValidator.withdrawValidatorFee(withdrawAmount);

        assertEq(s_conceroValidator.getWithdrawableValidatorFee(), totalFees - withdrawAmount);
    }

    function test_withdrawValidatorFee_RevertsIfInsufficientFees() public {
        uint256 depositAmount = s_conceroValidator.getMinimumDeposit();
        _deposit(depositAmount);

        bytes32 messageId = bytes32(uint256(1));
        bytes memory srcChainData = new bytes(0);

        vm.prank(s_relayer);
        s_conceroValidator.requestMessageReport(messageId, SRC_CHAIN_SELECTOR, srcChainData);

        uint256 withdrawAmount = depositAmount + 1;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InsufficientFee.selector, withdrawAmount, depositAmount)
        );

		vm.prank(s_deployer);
        s_conceroValidator.withdrawValidatorFee(withdrawAmount);
    }

    function test_withdrawValidatorFee_RevertsIfNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(CommonErrors.Unauthorized.selector, s_user));

        vm.prank(s_user);
        s_conceroValidator.withdrawValidatorFee(100e18);
    }
}
