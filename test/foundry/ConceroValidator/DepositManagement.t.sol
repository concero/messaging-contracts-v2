//// SPDX-License-Identifier: UNLICENSED
///* solhint-disable func-name-mixedcase */
///**
// * @title Security Reporting
// * @notice If you discover any security vulnerabilities, please report them responsibly.
// * @contact email: security@concero.io
// */
//pragma solidity 0.8.28;
//
//import {Errors} from "contracts/ConceroValidator/libraries/Errors.sol";
//import {CommonErrors} from "contracts/common/CommonErrors.sol";
//import {ConceroValidator} from "contracts/ConceroValidator/ConceroValidator.sol";
//import {CLFParams} from "contracts/ConceroValidator/libraries/Types.sol";
//import {ConceroValidatorTest} from "./base/ConceroValidatorTest.sol";
//
//contract DepositManagementTest is ConceroValidatorTest {
//    function setUp() public override {
//        super.setUp();
//    }
//
//    function test_deposit() public {
//        uint256 minimumDeposit = s_conceroValidator.getMinimumDeposit();
//
//        vm.deal(s_relayer, minimumDeposit);
//        assertEq(s_conceroValidator.getDeposit(s_relayer), 0);
//
//        vm.prank(s_relayer);
//        s_conceroValidator.deposit{value: minimumDeposit}();
//
//        assertEq(s_conceroValidator.getDeposit(s_relayer), minimumDeposit);
//        assertEq(address(s_conceroValidator).balance, minimumDeposit);
//    }
//
//    function test_deposit_RevertsIfInsufficientDeposit() public {
//        uint256 minimumDeposit = s_conceroValidator.getMinimumDeposit();
//        uint256 insufficientAmount = minimumDeposit - 1;
//
//        vm.deal(s_relayer, insufficientAmount);
//
//        vm.expectRevert(
//            abi.encodeWithSelector(
//                Errors.InsufficientDeposit.selector,
//                insufficientAmount,
//                minimumDeposit
//            )
//        );
//
//        vm.prank(s_relayer);
//        s_conceroValidator.deposit{value: insufficientAmount}();
//    }
//
//    function test_withdrawDeposit() public {
//        uint256 depositAmount = s_conceroValidator.getMinimumDeposit() * 2;
//
//        vm.deal(s_relayer, depositAmount);
//
//        vm.prank(s_relayer);
//        s_conceroValidator.deposit{value: depositAmount}();
//
//        assertEq(s_conceroValidator.getDeposit(s_relayer), depositAmount);
//
//        uint256 withdrawAmount = depositAmount / 2;
//
//        vm.prank(s_relayer);
//        s_conceroValidator.withdrawDeposit(withdrawAmount);
//
//        assertEq(s_conceroValidator.getDeposit(s_relayer), depositAmount - withdrawAmount);
//        assertEq(address(s_relayer).balance, withdrawAmount);
//    }
//
//    function test_withdrawDeposit_RevertsIfInsufficientDeposit() public {
//        uint256 depositAmount = s_conceroValidator.getMinimumDeposit();
//
//        vm.deal(s_relayer, depositAmount);
//
//        vm.prank(s_relayer);
//        s_conceroValidator.deposit{value: depositAmount}();
//
//        uint256 withdrawAmount = depositAmount + 1;
//
//        vm.expectRevert(
//            abi.encodeWithSelector(
//                Errors.InsufficientDeposit.selector,
//                depositAmount,
//                withdrawAmount
//            )
//        );
//
//        vm.prank(s_relayer);
//        s_conceroValidator.withdrawDeposit(withdrawAmount);
//    }
//
//    function test_getDeposit() public {
//        uint256 depositAmount = s_conceroValidator.getMinimumDeposit();
//
//        assertEq(s_conceroValidator.getDeposit(s_relayer), 0);
//
//        vm.deal(s_relayer, depositAmount);
//        vm.prank(s_relayer);
//        s_conceroValidator.deposit{value: depositAmount}();
//
//        assertEq(s_conceroValidator.getDeposit(s_relayer), depositAmount);
//    }
//
//    function test_getMinimumDeposit() public view {
//        uint256 minimumDeposit = s_conceroValidator.getMinimumDeposit();
//        uint256 clfCost = s_conceroValidator.getCLFCost();
//
//        assertEq(minimumDeposit, clfCost);
//        assertTrue(minimumDeposit > 0);
//    }
//
//    function test_constructor_RevertsIfPriceFeedIsZero() public {
//        CLFParams memory clfParams = CLFParams({
//            router: s_clfRouter,
//            donId: s_clfDonId,
//            subscriptionId: s_conceroValidatorSubscriptionId,
//            requestCLFMessageReportJsCodeHash: s_clfMessageReportRequestJsHashSum
//        });
//
//        vm.expectRevert(abi.encodeWithSelector(CommonErrors.InvalidAddress.selector));
//
//        new ConceroValidator(SRC_CHAIN_SELECTOR, address(0), clfParams);
//    }
//}
