// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/Console.sol";
import {Utils as CommonUtils} from "contracts/common/libraries/Utils.sol";
import {CommonConstants} from "contracts/common/CommonConstants.sol";

import {ConceroVerifierTest} from "./base/ConceroVerifierTest.sol";
import {MessageReport} from "../scripts/MockCLFReport/MessageReport.sol";

contract FeeCalculationTest is ConceroVerifierTest {
    function setUp() public override {
        super.setUp();

        _setPriceFeeds();
        _setGasFeeConfig();
        _setOperatorIsRegistered();
    }

    function test_FeeWithheldCorrectly() public returns (bytes32) {
        assertEq(address(conceroVerifier).balance, 0);
        assertEq(operator.balance, 0);

        uint256 minimumDeposit = conceroVerifier.getCLFCost();
        vm.deal(operator, minimumDeposit);

        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: minimumDeposit}(operator);
        assertEq(conceroVerifier.getOperatorDeposit(operator), minimumDeposit);

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

        assertEq(conceroVerifier.getOperatorDeposit(operator), 0);
        assertEq(address(conceroVerifier).balance, minimumDeposit);
        assertEq(conceroVerifier.getWithdrawableConceroFee(), 0);

        return clfRequestId;
    }

    function test_OperatorFeeAndDepositCalculatesCorrectly() public {
        bytes32 clfRequestId = test_FeeWithheldCorrectly();

        MessageReport messageReport = new MessageReport();
        bytes memory clfResponse = messageReport.getResponse();

        vm.prank(address(clfRouter));
        conceroVerifier.handleOracleFulfillment(clfRequestId, clfResponse, "");

        // Check that the operator deposit increased
        uint256 operatorDepositBeforeRequest = conceroVerifier.getCLFCost();
        uint256 vrfMsgReportRequestGasCost = VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD * LAST_GAS_PRICE;

        assertEq(
            conceroVerifier.getOperatorDeposit(operator),
            operatorDepositBeforeRequest + vrfMsgReportRequestGasCost
        );

        // Check that the operator fee increased
        uint256 operatorFeeMessageReportRequest = CommonUtils.convertUsdBpsToNative(
            CommonConstants.OPERATOR_FEE_MESSAGE_REPORT_REQUEST_BPS_USD,
            NATIVE_USD_RATE
        );
        assertEq(conceroVerifier.getOperatorFeesEarned(operator), operatorFeeMessageReportRequest);

        // Check ConceroVerifier balance
        assertEq(conceroVerifier.getWithdrawableConceroFee(), 0);
        assertEq(address(conceroVerifier).balance, operatorDepositBeforeRequest);

        // Send the gas cost and fee to the verifier
        vm.deal(
            address(conceroVerifier),
            operatorDepositBeforeRequest +
                vrfMsgReportRequestGasCost +
                operatorFeeMessageReportRequest
        );

        // Check Concero fee balance
        assertEq(conceroVerifier.getWithdrawableConceroFee(), 0);

        // Withdraw the operator fee
        vm.startPrank(operator);
        conceroVerifier.withdrawOperatorFee(operatorFeeMessageReportRequest);
        assertEq(operator.balance, operatorFeeMessageReportRequest);

        // Withdraw the operator deposit
        conceroVerifier.withdrawOperatorDeposit(
            operatorDepositBeforeRequest + vrfMsgReportRequestGasCost
        );
        assertEq(
            operator.balance,
            operatorDepositBeforeRequest +
                vrfMsgReportRequestGasCost +
                operatorFeeMessageReportRequest
        );

        vm.stopPrank();

        assertEq(address(conceroVerifier).balance, 0);
    }
}
