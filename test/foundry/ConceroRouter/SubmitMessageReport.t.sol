// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/Console.sol";
import {Vm} from "forge-std/src/Vm.sol";

import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {CommonConstants, ReportByteSizes} from "contracts/common/CommonConstants.sol";
import {Utils as CommonUtils} from "contracts/common/libraries/Utils.sol";
import {Message as MessageLib} from "contracts/common/libraries/Message.sol";

import {Types} from "contracts/ConceroRouter/libraries/Types.sol";
import {Namespaces} from "contracts/ConceroRouter/libraries/Storage.sol";
import {RouterSlots, OperatorSlots} from "contracts/ConceroRouter/libraries/StorageSlots.sol";
import {Types as VerifierTypes} from "contracts/ConceroVerifier/libraries/Types.sol";

import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";
import {MessageReport} from "../scripts/MockCLFReport/MessageReport.sol";

import {IConceroClient} from "contracts/interfaces/IConceroClient.sol";

contract SubmitMessageReport is ConceroRouterTest {
    MessageReport internal messageReport;
    address internal mockReceiver;
    bytes32 internal constant TEST_MESSAGE_ID = bytes32(uint256(1));
    bytes internal constant TEST_MESSAGE = "Test message";
    uint256 internal constant GAS_LIMIT = 1_000_000;

    event ConceroMessageReceived(bytes32 indexed messageId);
    event ConceroMessageDelivered(bytes32 indexed messageId);

    function setUp() public override {
        super.setUp();
        messageReport = new MessageReport();

        _setPriceFeeds();
    }

    function test_SubmitMessageReport() public {
        bytes memory dstChainDataRaw = abi.encode(address(conceroClient), GAS_LIMIT);

        bytes32 reportConfig = bytes32(
            (uint256(uint8(CommonTypes.CLFReportType.Message)) << 248) |
                (uint256(1) << 240) |
                (uint256(uint160(operator)))
        );

        bytes[] memory operators = new bytes[](1);
        operators[0] = abi.encode(operator);

        bytes memory encodedDstChainData = abi.encode(
            uint32(dstChainDataRaw.length),
            dstChainDataRaw
        );

        bytes32 internalMessageConfig = MessageLib.buildInternalMessageConfig(
            CLIENT_MESSAGE_CONFIG,
            SRC_CHAIN_SELECTOR
        );

        bytes[] memory allowedOperators = new bytes[](1);
        allowedOperators[0] = abi.encode(operator);

        bytes memory encodedResult = abi.encode(
            reportConfig,
            internalMessageConfig,
            TEST_MESSAGE_ID,
            keccak256(TEST_MESSAGE),
            dstChainDataRaw,
            allowedOperators
        );

        Types.ClfDonReportSubmission memory reportSubmission = messageReport.createMockClfReport(
            encodedResult
        );

        vm.recordLogs();

        vm.prank(operator);
        vm.resetGasMetering();
        conceroRouter.submitMessageReport(reportSubmission, TEST_MESSAGE);
        vm.pauseGasMetering();
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bool foundReceivedEvent = false;
        bool foundDeliveredEvent = false;

        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("ConceroMessageReceived(bytes32)")) {
                foundReceivedEvent = true;
                assertEq(
                    entries[i].topics[1],
                    TEST_MESSAGE_ID,
                    "ConceroMessageReceived event has incorrect messageId"
                );
            }
            if (entries[i].topics[0] == keccak256("ConceroMessageDelivered(bytes32)")) {
                foundDeliveredEvent = true;
                assertEq(
                    entries[i].topics[1],
                    TEST_MESSAGE_ID,
                    "ConceroMessageDelivered event has incorrect messageId"
                );
            }
        }

        assertTrue(foundReceivedEvent, "ConceroMessageReceived event not emitted");
        assertTrue(foundDeliveredEvent, "ConceroMessageDelivered event not emitted");

        assertTrue(
            conceroRouter.getStorage(
                Namespaces.ROUTER,
                RouterSlots.isMessageProcessed,
                TEST_MESSAGE_ID
            ) == 1,
            "Message should be marked as processed"
        );

        uint256 expectedFees = CommonUtils.convertUsdBpsToNative(
            CommonConstants.OPERATOR_FEE_MESSAGE_RELAY_BPS_USD,
            NATIVE_USD_RATE
        );
        assertEq(
            conceroRouter.getStorage(
                Namespaces.OPERATOR,
                OperatorSlots.feesEarnedNative,
                bytes32(uint256(uint160(operator)))
            ),
            expectedFees,
            "Operator should earn correct fees"
        );
    }

    // function testRevert_MessageAlreadyProcessed() public {

    //     VerifierTypes.MessageReportResult memory result = VerifierTypes.MessageReportResult({
    //         version: 1,
    //         reportType: VerifierTypes.CLFReportType.Message,
    //         operator: operator,
    //         internalMessageConfig: MessageLib.buildInternalMessageConfig(
    //             CLIENT_MESSAGE_CONFIG,
    //             SRC_CHAIN_SELECTOR
    //         ),
    //         messageId: TEST_MESSAGE_ID,
    //         messageHashSum: keccak256(TEST_MESSAGE),
    //         dstChainData: abi.encode(
    //             Types.EvmDstChainData({receiver: mockReceiver, gasLimit: GAS_LIMIT})
    //         ),
    //         allowedOperators: new bytes[](0)
    //     });

    //     bytes memory response = abi.encode(result);
    //     MockCLFReport.ClfDonReportSubmission memory reportSubmission = mockClfReport
    //         .createMockClfReport(response);

    //     vm.expectRevert(
    //         abi.encodeWithSelector(Errors.MessageAlreadyProcessed.selector, TEST_MESSAGE_ID)
    //     );
    //     conceroRouter.submitMessageReport(reportSubmission, TEST_MESSAGE);
    // }

    // function testRevert_InvalidMessageHashSum() public {
    //     // Set received message with different hash
    //     _setReceivedMessage(TEST_MESSAGE_ID, bytes32(uint256(1)));

    //     CommonTypes.MessageReportResult memory result = CommonTypes.MessageReportResult({
    //         version: 1,
    //         reportType: CommonTypes.CLFReportType.Message,
    //         operator: operator,
    //         internalMessageConfig: MessageLib.buildInternalMessageConfig(
    //             CLIENT_MESSAGE_CONFIG,
    //             SRC_CHAIN_SELECTOR
    //         ),
    //         messageId: TEST_MESSAGE_ID,
    //         messageHashSum: bytes32(0), // Invalid hash
    //         dstChainData: abi.encode(
    //             Types.EvmDstChainData({receiver: mockReceiver, gasLimit: GAS_LIMIT})
    //         ),
    //         allowedOperators: new bytes[](0)
    //     });

    //     bytes memory response = abi.encode(result);
    //     MockCLFReport.ClfDonReportSubmission memory reportSubmission = mockClfReport
    //         .createMockClfReport(response);

    //     vm.expectRevert(Errors.InvalidMessageHashSum.selector);
    //     conceroRouter.submitMessageReport(reportSubmission, TEST_MESSAGE);
    // }
}
