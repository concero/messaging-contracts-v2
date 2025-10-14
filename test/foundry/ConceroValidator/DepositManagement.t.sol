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
import {ConceroValidator} from "contracts/ConceroValidator/ConceroValidator.sol";
import {CLFParams} from "contracts/ConceroValidator/libraries/Types.sol";

import {ConceroValidatorTest} from "./base/ConceroValidatorTest.sol";

contract DepositManagementTest is ConceroValidatorTest {
    function setUp() public override {
        super.setUp();
    }

    function test_deposit() public {
        uint256 minimumDeposit = conceroValidator.getMinimumDeposit();

        vm.deal(relayer, minimumDeposit);
        assertEq(conceroValidator.getDeposit(relayer), 0);

        vm.prank(relayer);
        conceroValidator.deposit{value: minimumDeposit}();

        assertEq(conceroValidator.getDeposit(relayer), minimumDeposit);
        assertEq(address(conceroValidator).balance, minimumDeposit);
    }

    function test_deposit_RevertsIfInsufficientDeposit() public {
        uint256 minimumDeposit = conceroValidator.getMinimumDeposit();
        uint256 insufficientAmount = minimumDeposit - 1;

        vm.deal(relayer, insufficientAmount);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InsufficientDeposit.selector,
                insufficientAmount,
                minimumDeposit
            )
        );

        vm.prank(relayer);
        conceroValidator.deposit{value: insufficientAmount}();
    }

    function test_withdrawDeposit() public {
        uint256 depositAmount = conceroValidator.getMinimumDeposit() * 2;

        vm.deal(relayer, depositAmount);

        vm.prank(relayer);
        conceroValidator.deposit{value: depositAmount}();

        assertEq(conceroValidator.getDeposit(relayer), depositAmount);

        uint256 withdrawAmount = depositAmount / 2;

        vm.prank(relayer);
        conceroValidator.withdrawDeposit(withdrawAmount);

        assertEq(conceroValidator.getDeposit(relayer), depositAmount - withdrawAmount);
        assertEq(address(relayer).balance, withdrawAmount);
    }

    function test_withdrawDeposit_RevertsIfInsufficientDeposit() public {
        uint256 depositAmount = conceroValidator.getMinimumDeposit();

        vm.deal(relayer, depositAmount);

        vm.prank(relayer);
        conceroValidator.deposit{value: depositAmount}();

        uint256 withdrawAmount = depositAmount + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InsufficientDeposit.selector,
                depositAmount,
                withdrawAmount
            )
        );

        vm.prank(relayer);
        conceroValidator.withdrawDeposit(withdrawAmount);
    }

    function test_getDeposit() public {
        uint256 depositAmount = conceroValidator.getMinimumDeposit();

        assertEq(conceroValidator.getDeposit(relayer), 0);

        vm.deal(relayer, depositAmount);
        vm.prank(relayer);
        conceroValidator.deposit{value: depositAmount}();

        assertEq(conceroValidator.getDeposit(relayer), depositAmount);
    }

    function test_getMinimumDeposit() public view {
        uint256 minimumDeposit = conceroValidator.getMinimumDeposit();
        uint256 clfCost = conceroValidator.getCLFCost();

        assertEq(minimumDeposit, clfCost);
        assertTrue(minimumDeposit > 0);
    }

    function test_constructor_RevertsIfPriceFeedIsZero() public {
        CLFParams memory clfParams = CLFParams({
            router: clfRouter,
            donId: clfDonId,
            subscriptionId: clfSubscriptionId,
            requestCLFMessageReportJsCodeHash: clfMessageReportRequestJsHashSum
        });

        vm.expectRevert(abi.encodeWithSelector(CommonErrors.InvalidAddress.selector));

        new ConceroValidator(SRC_CHAIN_SELECTOR, address(0), clfParams);
    }
}
