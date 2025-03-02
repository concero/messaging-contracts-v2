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

    // function test_SubmitMessageReportWithExactParameters() public {
    //     // Create the exact parameters from the example
    //     bytes32[3] memory context = [
    //         bytes32(0x636f6e7465787430000000000000000000000000000000000000000000000000),
    //         bytes32(0x636f6e7465787431000000000000000000000000000000000000000000000000),
    //         bytes32(0x636f6e7465787432000000000000000000000000000000000000000000000000)
    //     ];

    //     bytes
    //         memory report = hex"00000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000002e0000000000000000000000000000000000000000000000000000000000000034000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000001c4ccd233386668a5af1f4583f1e6e7a87c194be4a37664452056b35691e50e930000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000001a0000100000000000000000000eee38505c47acba0c866df7265bd3e25da596b2701000001000000000000010001000100000000000000000000000000000000009a92ea9d0e1197127a2e78c4b2526dec574265983befc9759b2d113161b44438acaf3289d7b601cbd114fb36c4d29c85bbfd5e133f14cb355c3fd8d99367964f00000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000003f7000000000000000000000000ccccac597660eebf71b424415f874ee4c6b13d22000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000eee38505c47acba0c866df7265bd3e25da596b27000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000160c4ccd233386668a5af1f4583f1e6e7a87c194be4a37664452056b35691e50e9300000000000000000000000012345678901234567890123456789012345678900000000000000000000000000000000000000000000000000de0b6b3a7640000000000000000000000000000a45f4a08ece764a74ce20306d704e7cbd755d8a4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000186a00000000000000000000000000000000000000000000000000de0b6b3a76400000000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000000000000000000186a000000000000000000000000000000000000000000000000000000000000186a000000000000000000000000000000000000000000000000000000000000186a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000";

    //     bytes32[] memory rs = new bytes32[](3);
    //     rs[0] = 0x60b79612f4c8d72b167f2b5038cad434801c0a72fdb2cdc73ba0979e6152e3ca;
    //     rs[1] = 0x358cc63f1c26e0222a1f027b045e839f7fd483d33a3e3f02acaee0a527019f2a;
    //     rs[2] = 0xb14f1ae9c00f8f637cdf764019840e48c7e972fd94446adee1f28818fd86c58d;

    //     bytes32[] memory ss = new bytes32[](3);
    //     ss[0] = 0x487111e13214312aeaaddb9dcd9e051b299aef42e5ee7a1f09ccc41c1676e22c;
    //     ss[1] = 0x45e802fea16421d5a21df758cc17890f89eaaf2b47fd31d2add8a62c9bbebe1f;
    //     ss[2] = 0x68eee884f20e34a3224839d0c229711c2f2d12de89a98f0419c5c64c2dd53f01;

    //     bytes32 rawVs = 0x0000000000000000000000000000000000000000000000000000000000010000;

    //     Types.ClfDonReportSubmission memory reportSubmission = Types.ClfDonReportSubmission({
    //         context: context,
    //         report: report,
    //         rs: rs,
    //         ss: ss,
    //         rawVs: rawVs
    //     });

    //     bytes memory message = "Hello, World!";

    //     // Set up the operator address from the report
    //     address operatorFromReport = 0xeeE38505C47acBa0C866df7265bd3E25DA596b27;
    //     vm.prank(operatorFromReport);

    //     // Record logs to verify events
    //     vm.recordLogs();

    //     // Submit the message report with exact parameters
    //     conceroRouter.submitMessageReport(reportSubmission, message);

    //     // Verify expected events were emitted
    //     Vm.Log[] memory entries = vm.getRecordedLogs();
    //     bool foundReceivedEvent = false;
    //     bool foundDeliveredEvent = false;

    //     for (uint256 i = 0; i < entries.length; i++) {
    //         if (entries[i].topics[0] == keccak256("ConceroMessageReceived(bytes32)")) {
    //             foundReceivedEvent = true;
    //         }
    //         if (entries[i].topics[0] == keccak256("ConceroMessageDelivered(bytes32)")) {
    //             foundDeliveredEvent = true;
    //         }
    //     }

    //     assertTrue(foundReceivedEvent, "ConceroMessageReceived event not emitted");
    //     assertTrue(foundDeliveredEvent, "ConceroMessageDelivered event not emitted");
    // }

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
