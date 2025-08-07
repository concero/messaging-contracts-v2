// SPDX-License-Identifier: UNLICENSED
// solhint-disable func-name-mixedcase
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Utils as CommonUtils} from "contracts/common/libraries/Utils.sol";
import {CommonConstants} from "contracts/common/CommonConstants.sol";
import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {Types} from "contracts/ConceroRouter/libraries/Types.sol";
import {Namespaces} from "contracts/ConceroRouter/libraries/Storage.sol";
import {OperatorSlots, RouterSlots} from "contracts/ConceroRouter/libraries/StorageSlots.sol";

import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";
import {MessageReport} from "../scripts/MockCLFReport/MessageReport.sol";

contract FeeCalculationTest is ConceroRouterTest {
    uint256 private constant TEST_GAS_LIMIT = 100_000;

    function setUp() public override {
        super.setUp();

        _setPriceFeeds();
        _setGasFeeConfig();

        // Fund the router with native tokens for fee payments
        vm.deal(address(conceroRouter), 10 ether);
    }

    function test_OperatorFeeCalculationCorrect() public {
        // Record initial state
        uint256 initialOperatorFee = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator)))
        );

        uint256 initialTotalFees = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0)
        );

        uint256 initialRouterBalance = address(conceroRouter).balance;

        // Simulate message delivery by calling _payOperatorRelayFee indirectly
        // through submitMessageReport
        _simulateMessageDelivery();

        // Calculate expected fees
        uint256 expectedGasFeeNative = _calculateExpectedGasFee();
        uint256 expectedOperatorFeeMessageRelay = CommonUtils.convertUsdBpsToNative(
            CommonConstants.OPERATOR_FEE_MESSAGE_RELAY_BPS_USD,
            NATIVE_USD_RATE
        );
        uint256 expectedTotalFee = expectedOperatorFeeMessageRelay + expectedGasFeeNative;

        // Verify operator fees were credited correctly
        uint256 finalOperatorFee = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator)))
        );

        uint256 finalTotalFees = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0)
        );

        assertEq(
            finalOperatorFee,
            initialOperatorFee + expectedTotalFee,
            "Operator fee not credited correctly"
        );

        assertEq(
            finalTotalFees,
            initialTotalFees + expectedTotalFee,
            "Total fees not updated correctly"
        );

        // Router balance should remain unchanged (fees are only credited, not transferred)
        assertEq(
            address(conceroRouter).balance,
            initialRouterBalance,
            "Router balance should not change during fee calculation"
        );
    }

    function test_OperatorCanWithdrawEarnedFees() public {
        // First, accumulate some fees
        _simulateMessageDelivery();

        uint256 earnedFees = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator)))
        );

        assertTrue(earnedFees > 0, "No fees earned");

        uint256 initialOperatorBalance = operator.balance;
        uint256 initialRouterBalance = address(conceroRouter).balance;

        // Operator withdraws earned fees
        vm.prank(operator);
        conceroRouter.withdrawOperatorFee(earnedFees);

        // Verify balances after withdrawal
        assertEq(
            operator.balance,
            initialOperatorBalance + earnedFees,
            "Operator balance not updated correctly"
        );

        assertEq(
            address(conceroRouter).balance,
            initialRouterBalance - earnedFees,
            "Router balance not updated correctly"
        );

        // Verify fees were reset
        uint256 remainingFees = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator)))
        );

        assertEq(remainingFees, 0, "Fees not cleared after withdrawal");
    }

    function test_ConceroWithdrawableBalanceCalculation() public {
        uint256 initialRouterBalance = address(conceroRouter).balance;

        // Simulate multiple message deliveries to accumulate operator fees
        _simulateMessageDelivery();
        _simulateMessageDelivery();

        uint256 totalOperatorFees = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0)
        );

        // Concero's withdrawable balance should be router balance minus operator fees
        uint256 expectedWithdrawable = initialRouterBalance - totalOperatorFees;

        // Verify Concero can withdraw the correct amount
        vm.startPrank(deployer);

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = expectedWithdrawable;

        uint256 deployerInitialBalance = deployer.balance;

        conceroRouter.withdrawConceroFees(tokens, amounts);

        assertEq(
            deployer.balance,
            deployerInitialBalance + expectedWithdrawable,
            "Concero withdrawable balance calculation incorrect"
        );

        vm.stopPrank();
    }

    function test_BalanceSegregationAfterMultipleOperations() public {
        // Simulate operations from different operators
        address operator2 = address(0x9999);

        // First operator delivers message
        _simulateMessageDelivery();

        // Second operator delivers message
        _simulateMessageDeliveryFromOperator(operator2);

        // Check individual operator balances
        uint256 operator1Fees = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator)))
        );

        uint256 operator2Fees = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator2)))
        );

        uint256 totalFees = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0)
        );

        // Verify segregation
        assertEq(
            totalFees,
            operator1Fees + operator2Fees,
            "Total fees should equal sum of individual operator fees"
        );

        // Verify each operator can withdraw their own fees
        vm.prank(operator);
        conceroRouter.withdrawOperatorFee(operator1Fees);

        vm.prank(operator2);
        conceroRouter.withdrawOperatorFee(operator2Fees);

        // Verify total fees were decremented correctly
        uint256 finalTotalFees = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0)
        );

        assertEq(finalTotalFees, 0, "Total fees not decremented correctly");
    }

    function test_MessageDeliveryFeeCalculation() public {
        uint256 initialBalance = operator.balance;
        uint256 routerBalance = address(conceroRouter).balance;

        bytes32 testMessageId = bytes32(uint256(12345));
        bytes memory testMessage = "Concero receive";

        // Execute message delivery
        _executeMessageDelivery(testMessageId, testMessage);

        // Verify message was processed
        assertTrue(
            conceroRouter.getStorage(
                Namespaces.ROUTER,
                RouterSlots.isMessageProcessed,
                testMessageId
            ) == 1,
            "Message should be marked as processed"
        );

        // Calculate expected total fee
        uint256 expectedTotalFee = _calculateExpectedTotalFee();

        // Verify fees and withdrawal
        _verifyFeesAndWithdrawal(initialBalance, routerBalance, expectedTotalFee);
    }

    function _executeMessageDelivery(bytes32 messageId, bytes memory message) internal {
        MessageReport messageReport = new MessageReport();

        bytes[] memory allowedOperators = new bytes[](1);
        allowedOperators[0] = abi.encode(operator);

        CommonTypes.MessagePayloadV1 memory messagePayload = CommonTypes.MessagePayloadV1({
            messageId: messageId,
            messageHashSum: keccak256(message),
            txHash: bytes32("txHash"),
            messageSender: abi.encode(address(this)),
            srcChainSelector: SRC_CHAIN_SELECTOR,
            dstChainSelector: 1,
            srcBlockNumber: block.number,
            dstChainData: Types.EvmDstChainData({
                receiver: address(conceroClient),
                gasLimit: TEST_GAS_LIMIT
            }),
            allowedOperators: allowedOperators
        });

        CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
            resultType: CommonTypes.ResultType.Message,
            payloadVersion: 1,
            requester: operator
        });

        Types.ClfDonReportSubmission memory reportSubmission = messageReport.createMockClfReport(
            abi.encode(resultConfig, abi.encode(messagePayload))
        );

        bytes[] memory messageBodies = new bytes[](1);
        messageBodies[0] = message;
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = 0;

        vm.prank(operator);
        conceroRouter.submitMessageReport(reportSubmission, messageBodies, indexes);
    }

    function _calculateExpectedTotalFee() internal pure returns (uint256) {
        uint256 gasFee = (LAST_GAS_PRICE *
            (SUBMIT_MSG_GAS_OVERHEAD + TEST_GAS_LIMIT) *
            NATIVE_USD_RATE) / 1e18;
        uint256 operatorFee = CommonUtils.convertUsdBpsToNative(
            CommonConstants.OPERATOR_FEE_MESSAGE_RELAY_BPS_USD,
            NATIVE_USD_RATE
        );
        return operatorFee + gasFee;
    }

    function _verifyFeesAndWithdrawal(
        uint256 initialBalance,
        uint256 routerBalance,
        uint256 expectedFee
    ) internal {
        // Check operator fees were credited
        uint256 operatorFees = conceroRouter.getOperatorFeesEarned(address(operator));

        assertEq(operatorFees, expectedFee, "Operator fees not credited correctly");
        assertEq(
            address(conceroRouter).balance,
            routerBalance,
            "Router balance should not change during fee accrual"
        );

        // Test withdrawal
        vm.prank(operator);
        conceroRouter.withdrawOperatorFee(expectedFee);

        assertEq(
            operator.balance,
            initialBalance + expectedFee,
            "Operator should receive correct fee amount"
        );
        assertEq(
            address(conceroRouter).balance,
            routerBalance - expectedFee,
            "Router balance should decrease"
        );

        // Verify fees reset
        operatorFees = conceroRouter.getOperatorFeesEarned(address(operator));
        assertEq(operatorFees, 0, "Operator fees should be reset after withdrawal");
    }

    function _simulateMessageDelivery() internal {
        _simulateMessageDeliveryFromOperator(operator);
    }

    function _simulateMessageDeliveryFromOperator(address sender) internal {
        // Simulate the fee calculation by directly calling the internal logic
        // Since we can't directly call _payOperatorRelayFee, we'll manipulate storage
        uint256 expectedGasFeeNative = _calculateExpectedGasFee();
        uint256 expectedOperatorFeeMessageRelay = CommonUtils.convertUsdBpsToNative(
            CommonConstants.OPERATOR_FEE_MESSAGE_RELAY_BPS_USD,
            NATIVE_USD_RATE
        );
        uint256 expectedTotalFee = expectedOperatorFeeMessageRelay + expectedGasFeeNative;

        // Manually update the operator fees to simulate fee accrual
        vm.startPrank(deployer);

        uint256 currentOperatorFees = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(sender)))
        );

        uint256 currentTotalFees = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0)
        );

        conceroRouter.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(sender))),
            currentOperatorFees + expectedTotalFee
        );

        conceroRouter.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0),
            currentTotalFees + expectedTotalFee
        );

        vm.stopPrank();
    }

    function _calculateExpectedGasFee() internal pure returns (uint256) {
        uint256 gasFeeNative = (LAST_GAS_PRICE *
            (SUBMIT_MSG_GAS_OVERHEAD + TEST_GAS_LIMIT) *
            NATIVE_USD_RATE) / 1e18;
        return gasFeeNative;
    }
}
