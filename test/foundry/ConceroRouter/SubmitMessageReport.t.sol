//// SPDX-License-Identifier: UNLICENSED
//// solhint-disable func-name-mixedcase
///**
// * @title Security Reporting
// * @notice If you discover any security vulnerabilities, please report them responsibly.
// * @contact email: security@concero.io
// */
//pragma solidity 0.8.28;
//
//import {console} from "forge-std/src/Console.sol";
//import {Vm} from "forge-std/src/Vm.sol";
//
//import {CommonTypes} from "contracts/common/CommonTypes.sol";
//import {CommonConstants, ReportByteSizes} from "contracts/common/CommonConstants.sol";
//import {Utils as CommonUtils} from "contracts/common/libraries/Utils.sol";
//import {Message as MessageLib} from "contracts/common/libraries/Message.sol";
//
//import {Types} from "contracts/ConceroRouter/libraries/Types.sol";
//import {Namespaces} from "contracts/ConceroRouter/libraries/Storage.sol";
//import {RouterSlots, OperatorSlots} from "contracts/ConceroRouter/libraries/StorageSlots.sol";
//
//import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";
//import {MessageReport as MockCLFReport} from "../scripts/MockCLFReport/MessageReport.sol";
//
//import {IConceroClient} from "contracts/interfaces/IConceroClient.sol";
//import {CommonErrors} from "contracts/common/CommonErrors.sol";
//
//contract SubmitMessageReport is ConceroRouterTest {
//    MockCLFReport internal mockClfReport;
//    address internal mockReceiver;
//    bytes32 internal constant TEST_MESSAGE_ID = bytes32(uint256(1));
//    bytes internal constant TEST_MESSAGE = "Test message";
//    uint256 internal constant GAS_LIMIT = 1_000_000;
//
//    event ConceroMessageReceived(bytes32 indexed messageId);
//    event ConceroMessageDelivered(bytes32 indexed messageId);
//
//    function setUp() public override {
//        super.setUp();
//        mockClfReport = new MockCLFReport();
//
//        _setPriceFeeds();
//        _setGasFeeConfig();
//    }
//
//    function test_SubmitMessageReport() public {
//        vm.recordLogs();
//
//        Types.EvmDstChainData memory dstChainData = Types.EvmDstChainData({
//            receiver: address(conceroClient),
//            gasLimit: GAS_LIMIT
//        });
//
//        CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
//            resultType: CommonTypes.ResultType.Message,
//            payloadVersion: 1,
//            requester: operator
//        });
//
//        bytes[] memory allowedOperators = new bytes[](1);
//        allowedOperators[0] = abi.encode(operator);
//
//        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = CommonTypes.MessagePayloadV1({
//            messageId: TEST_MESSAGE_ID,
//            messageHashSum: keccak256(TEST_MESSAGE),
//            txHash: bytes32("txHash"),
//            messageSender: abi.encode(address(this)),
//            srcChainSelector: SRC_CHAIN_SELECTOR,
//            dstChainSelector: 1,
//            srcBlockNumber: block.number,
//            dstChainData: dstChainData,
//            allowedOperators: allowedOperators
//        });
//
//        bytes memory payload = abi.encode(messagePayloadV1);
//
//        Types.ClfDonReportSubmission memory reportSubmission = mockClfReport.createMockClfReport(
//            abi.encode(resultConfig, payload)
//        );
//
//        bytes[] memory messageBodies = new bytes[](1);
//        messageBodies[0] = TEST_MESSAGE;
//        uint256[] memory indexes = new uint256[](1);
//        indexes[0] = 0;
//
//        vm.prank(operator);
//        conceroRouter.submitMessageReport(reportSubmission, messageBodies, indexes);
//
//        Vm.Log[] memory entries = vm.getRecordedLogs();
//
//        bool foundReceivedEvent = false;
//        bool foundDeliveredEvent = false;
//
//        for (uint256 i = 0; i < entries.length; i++) {
//            if (entries[i].topics[0] == keccak256("ConceroMessageReceived(bytes32)")) {
//                foundReceivedEvent = true;
//                assertEq(
//                    entries[i].topics[1],
//                    TEST_MESSAGE_ID,
//                    "ConceroMessageReceived event has incorrect messageId"
//                );
//            }
//            if (entries[i].topics[0] == keccak256("ConceroMessageDelivered(bytes32)")) {
//                foundDeliveredEvent = true;
//                assertEq(
//                    entries[i].topics[1],
//                    TEST_MESSAGE_ID,
//                    "ConceroMessageDelivered event has incorrect messageId"
//                );
//            }
//        }
//
//        assertTrue(foundReceivedEvent, "ConceroMessageReceived event not emitted");
//        assertTrue(foundDeliveredEvent, "ConceroMessageDelivered event not emitted");
//
//        assertTrue(
//            conceroRouter.getStorage(
//                Namespaces.ROUTER,
//                RouterSlots.isMessageProcessed,
//                TEST_MESSAGE_ID
//            ) == 1,
//            "Message should be marked as processed"
//        );
//
//        uint256 actualFees = conceroRouter.getStorage(
//            Namespaces.OPERATOR,
//            OperatorSlots.feesEarnedNative,
//            bytes32(uint256(uint160(operator)))
//        );
//        assertTrue(actualFees > 0, "Operator should earn some fees");
//    }
//
//    function test_submitMessageReport_RevertsIfNativeUsdRateIsZero() public {
//        // Set nativeUsdRate to 0
//        vm.startPrank(feedUpdater);
//        conceroPriceFeed.setNativeUsdRate(0);
//        vm.stopPrank();
//
//        // Create a basic message report
//        Types.EvmDstChainData memory dstChainData = Types.EvmDstChainData({
//            receiver: address(conceroClient),
//            gasLimit: GAS_LIMIT
//        });
//
//        CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
//            resultType: CommonTypes.ResultType.Message,
//            payloadVersion: 1,
//            requester: operator
//        });
//
//        bytes[] memory allowedOperators = new bytes[](1);
//        allowedOperators[0] = abi.encode(operator);
//
//        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = CommonTypes.MessagePayloadV1({
//            messageId: TEST_MESSAGE_ID,
//            messageHashSum: keccak256(TEST_MESSAGE),
//            txHash: bytes32("txHash"),
//            messageSender: abi.encode(address(this)),
//            srcChainSelector: SRC_CHAIN_SELECTOR,
//            dstChainSelector: 1,
//            srcBlockNumber: block.number,
//            dstChainData: dstChainData,
//            allowedOperators: allowedOperators
//        });
//
//        bytes memory payload = abi.encode(messagePayloadV1);
//        Types.ClfDonReportSubmission memory reportSubmission = mockClfReport.createMockClfReport(
//            abi.encode(resultConfig, payload)
//        );
//
//        bytes[] memory messageBodies = new bytes[](1);
//        messageBodies[0] = TEST_MESSAGE;
//        uint256[] memory indexes = new uint256[](1);
//        indexes[0] = 0;
//
//        vm.expectRevert(
//            abi.encodeWithSelector(
//                CommonErrors.RequiredVariableUnset.selector,
//                CommonErrors.RequiredVariableUnsetType.NativeUSDRate
//            )
//        );
//
//        vm.prank(operator);
//        conceroRouter.submitMessageReport(reportSubmission, messageBodies, indexes);
//    }
//
//    function test_submitMessageReport_RevertsIfLastGasPriceIsZero() public {
//        // Set lastGasPrice to 0 for current chain
//        vm.startPrank(feedUpdater);
//        uint24[] memory chainSelectors = new uint24[](1);
//        chainSelectors[0] = SRC_CHAIN_SELECTOR;
//        uint256[] memory gasPrices = new uint256[](1);
//        gasPrices[0] = 0;
//
//        conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);
//        vm.stopPrank();
//
//        // Create a basic message report
//        Types.EvmDstChainData memory dstChainData = Types.EvmDstChainData({
//            receiver: address(conceroClient),
//            gasLimit: GAS_LIMIT
//        });
//
//        CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
//            resultType: CommonTypes.ResultType.Message,
//            payloadVersion: 1,
//            requester: operator
//        });
//
//        bytes[] memory allowedOperators = new bytes[](1);
//        allowedOperators[0] = abi.encode(operator);
//
//        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = CommonTypes.MessagePayloadV1({
//            messageId: TEST_MESSAGE_ID,
//            messageHashSum: keccak256(TEST_MESSAGE),
//            txHash: bytes32("txHash"),
//            messageSender: abi.encode(address(this)),
//            srcChainSelector: SRC_CHAIN_SELECTOR,
//            dstChainSelector: 1,
//            srcBlockNumber: block.number,
//            dstChainData: dstChainData,
//            allowedOperators: allowedOperators
//        });
//
//        bytes memory payload = abi.encode(messagePayloadV1);
//        Types.ClfDonReportSubmission memory reportSubmission = mockClfReport.createMockClfReport(
//            abi.encode(resultConfig, payload)
//        );
//
//        bytes[] memory messageBodies = new bytes[](1);
//        messageBodies[0] = TEST_MESSAGE;
//        uint256[] memory indexes = new uint256[](1);
//        indexes[0] = 0;
//
//        vm.expectRevert(
//            abi.encodeWithSelector(
//                CommonErrors.RequiredVariableUnset.selector,
//                CommonErrors.RequiredVariableUnsetType.lastGasPrice
//            )
//        );
//
//        vm.prank(operator);
//        conceroRouter.submitMessageReport(reportSubmission, messageBodies, indexes);
//    }
//
//    function test_submitMessageReport_RevertsIfGasFeeNativeIsZero() public {
//        vm.startPrank(deployer);
//        conceroRouter.setGasFeeConfig(
//            SRC_CHAIN_SELECTOR,
//            0, // submitMsgGasOverhead = 0
//            VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD,
//            CLF_CALLBACK_GAS_OVERHEAD
//        );
//        vm.stopPrank();
//
//        uint24[] memory chainSelectors = new uint24[](1);
//        chainSelectors[0] = SRC_CHAIN_SELECTOR;
//        uint256[] memory gasPrices = new uint256[](1);
//        gasPrices[0] = 1;
//
//        vm.startPrank(feedUpdater);
//        conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);
//        conceroPriceFeed.setNativeUsdRate(1);
//        vm.stopPrank();
//
//        Types.EvmDstChainData memory dstChainData = Types.EvmDstChainData({
//            receiver: address(conceroClient),
//            gasLimit: 10000
//        });
//
//        CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
//            resultType: CommonTypes.ResultType.Message,
//            payloadVersion: 1,
//            requester: operator
//        });
//
//        bytes[] memory allowedOperators = new bytes[](1);
//        allowedOperators[0] = abi.encode(operator);
//
//        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = CommonTypes.MessagePayloadV1({
//            messageId: TEST_MESSAGE_ID,
//            messageHashSum: keccak256(TEST_MESSAGE),
//            txHash: bytes32("txHash"),
//            messageSender: abi.encode(address(this)),
//            srcChainSelector: SRC_CHAIN_SELECTOR,
//            dstChainSelector: 1,
//            srcBlockNumber: block.number,
//            dstChainData: dstChainData,
//            allowedOperators: allowedOperators
//        });
//
//        bytes memory payload = abi.encode(messagePayloadV1);
//        Types.ClfDonReportSubmission memory reportSubmission = mockClfReport.createMockClfReport(
//            abi.encode(resultConfig, payload)
//        );
//
//        bytes[] memory messageBodies = new bytes[](1);
//        messageBodies[0] = TEST_MESSAGE;
//        uint256[] memory indexes = new uint256[](1);
//        indexes[0] = 0;
//
//        vm.expectRevert(abi.encodeWithSelector(CommonErrors.InvalidAmount.selector));
//
//        vm.prank(operator);
//        conceroRouter.submitMessageReport(reportSubmission, messageBodies, indexes);
//    }
//
//    // function testRevert_MessageAlreadyProcessed() public {
//
//    //     VerifierTypes.MessageReportResult memory result = VerifierTypes.MessageReportResult({
//    //         version: 1,
//    //         reportType: VerifierTypes.CLFReportType.Message,
//    //         operator: operator,
//    //         internalMessageConfig: MessageLib.buildInternalMessageConfig(
//    //             CLIENT_MESSAGE_CONFIG,
//    //             SRC_CHAIN_SELECTOR
//    //         ),
//    //         messageId: TEST_MESSAGE_ID,
//    //         messageHashSum: keccak256(TEST_MESSAGE),
//    //         dstChainData: abi.encode(
//    //             Types.EvmDstChainData({receiver: mockReceiver, gasLimit: GAS_LIMIT})
//    //         ),
//    //         allowedOperators: new bytes[](0)
//    //     });
//
//    //     bytes memory response = abi.encode(result);
//    //     MockCLFReport.ClfDonReportSubmission memory reportSubmission = mockClfReport
//    //         .createMockClfReport(response);
//
//    //     vm.expectRevert(
//    //         abi.encodeWithSelector(Errors.MessageAlreadyProcessed.selector, TEST_MESSAGE_ID)
//    //     );
//    //     conceroRouter.submitMessageReport(reportSubmission, TEST_MESSAGE);
//    // }
//
//    // function testRevert_InvalidMessageHashSum() public {
//    //     // Set received message with different hash
//    //     _setReceivedMessage(TEST_MESSAGE_ID, bytes32(uint256(1)));
//
//    //     CommonTypes.MessageReportResult memory result = CommonTypes.MessageReportResult({
//    //         version: 1,
//    //         reportType: CommonTypes.CLFReportType.Message,
//    //         operator: operator,
//    //         internalMessageConfig: MessageLib.buildInternalMessageConfig(
//    //             CLIENT_MESSAGE_CONFIG,
//    //             SRC_CHAIN_SELECTOR
//    //         ),
//    //         messageId: TEST_MESSAGE_ID,
//    //         messageHashSum: bytes32(0), // Invalid hash
//    //         dstChainData: abi.encode(
//    //             Types.EvmDstChainData({receiver: mockReceiver, gasLimit: GAS_LIMIT})
//    //         ),
//    //         allowedOperators: new bytes[](0)
//    //     });
//
//    //     bytes memory response = abi.encode(result);
//    //     MockCLFReport.ClfDonReportSubmission memory reportSubmission = mockClfReport
//    //         .createMockClfReport(response);
//
//    //     vm.expectRevert(Errors.InvalidMessageHashSum.selector);
//    //     conceroRouter.submitMessageReport(reportSubmission, TEST_MESSAGE);
//    // }
//}
