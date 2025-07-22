// SPDX-License-Identifier: UNLICENSED
// solhint-disable func-name-mixedcase
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
import {CommonErrors} from "contracts/common/CommonErrors.sol";

contract SubmitMessageReport is ConceroRouterTest {
    MessageReport internal messageReport;
    address internal mockReceiver;
    bytes32 internal constant TEST_MESSAGE_ID = bytes32(uint256(1));
    bytes internal constant TEST_MESSAGE = "Test message";
    uint256 internal constant GAS_LIMIT = 1_000_000;
    //    uint24 internal constant DST_CHAIN_SELECTOR = 1;

    event ConceroMessageReceived(bytes32 indexed messageId);
    event ConceroMessageDelivered(bytes32 indexed messageId);

    function setUp() public override {
        super.setUp();
        messageReport = new MessageReport();

        _setPriceFeeds();
		_setGasFeeConfig();
    }

    function test_SubmitMessageReport() public {
        Types.EvmDstChainData memory dstChainData = Types.EvmDstChainData({
            receiver: address(conceroClient),
            gasLimit: GAS_LIMIT
        });

        CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
            resultType: CommonTypes.ResultType.Message,
            payloadVersion: 1,
            requester: operator
        });

        bytes[] memory allowedOperators = new bytes[](1);
        allowedOperators[0] = abi.encode(operator);

        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = CommonTypes.MessagePayloadV1({
            messageId: TEST_MESSAGE_ID,
            messageHashSum: keccak256(TEST_MESSAGE),
            messageSender: abi.encode(address(this)),
            srcChainSelector: SRC_CHAIN_SELECTOR,
            dstChainSelector: 1,
            srcBlockNumber: block.number,
            dstChainData: dstChainData,
            allowedOperators: allowedOperators
        });

        bytes memory payload = abi.encode(messagePayloadV1);

        Types.ClfDonReportSubmission memory reportSubmission = messageReport.createMockClfReport(
            abi.encode(resultConfig, payload)
        );

        vm.recordLogs();

        vm.prank(operator);
        vm.resetGasMetering();
        bytes[] memory messageBodies = new bytes[](1);
        messageBodies[0] = TEST_MESSAGE;
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = 0;
        conceroRouter.submitMessageReport(reportSubmission, messageBodies, indexes);
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
                    "ConceroMessageDelivered event not emitted with correct messageId"
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

    function test_SubmitMessageReportWithExactParameters() public {
        // Create the exact parameters from the example
        bytes32[3] memory context = [
            bytes32(0x636f6e7465787430000000000000000000000000000000000000000000000000),
            bytes32(0x636f6e7465787431000000000000000000000000000000000000000000000000),
            bytes32(0x636f6e7465787432000000000000000000000000000000000000000000000000)
        ];

        bytes
            memory report = hex"00000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000003e00000000000000000000000000000000000000000000000000000000000000440000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000017e502f807c512aa1e7adab58e8a9181e5436e0e7106797fa90f1f5ea2c93fffb0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000002a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000eee38505c47acba0c866df7265bd3e25da596b270000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000205f92fa865194e62ee00f86de9cd0d9b0fe71fef05611e2fa70a65c15348b2d18512833b7a85c8ecfa2572ffba8531e32ac3215e1bc0389d7b814def5ededebc100000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000100000000000000000000000007357547c8442f797dffa3b38c44024eb3b4ed15f00000000000000000000000000000000000000000000000000000000000186a0000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000200000000000000000000000007357547c8442f797dffa3b38c44024eb3b4ed15f000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000014eee38505c47acba0c866df7265bd3e25da596b270000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000001607e502f807c512aa1e7adab58e8a9181e5436e0e7106797fa90f1f5ea2c93fffb00000000000000000000000012345678901234567890123456789012345678900000000000000000000000000000000000000000000000000de0b6b3a7640000000000000000000000000000a45f4a08ece764a74ce20306d704e7cbd755d8a4000000000000000000000000000000000000000000000000000000000000000900000000000000000000000000000000000000000000000000000000000186a00000000000000000000000000000000000000000000000000de0b6b3a76400000000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000000000000000000186a000000000000000000000000000000000000000000000000000000000000186a000000000000000000000000000000000000000000000000000000000000186a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000";

        bytes32[] memory rs = new bytes32[](3);
        rs[0] = 0xd227ccf13a9c1e74fcbb150fc07af82a35b71eb2aa7c0d241958a93194dbb5df;
        rs[1] = 0x2e8025d8dca6b60966e936e9c394d8da016ceccd9f6ae12ac56b5bbc74072333;
        rs[2] = 0xec04e195e9f493557574e6171f35933510d22c8c4430db5ad1aca7b13071c6dc;

        bytes32[] memory ss = new bytes32[](3);
        ss[0] = 0x505421bf2300b093f24d59b1185afba05d9f929101f7a50f87d7ffb7c18db9e6;
        ss[1] = 0x67fe3f139a94553649e3847a90a1e93eaa536192c9db130b9db281ad6ffdbb8d;
        ss[2] = 0x7af0146f4116384edd54ea32a07de5bf04bbb5557363aff46c5d9f77a1a9e837;

        bytes32 rawVs = 0x0000010000000000000000000000000000000000000000000000000000000000;

        bytes[] memory messageBodies = new bytes[](1);
        messageBodies[0] = hex"48656c6c6f2066726f6d20436f6e6365726f21";

        uint256[] memory indexes = new uint256[](1);
        indexes[0] = 0;

        Types.ClfDonReportSubmission memory reportSubmission = Types.ClfDonReportSubmission({
            context: context,
            report: report,
            rs: rs,
            ss: ss,
            rawVs: rawVs
        });

        address operatorFromReport = 0xeeE38505C47acBa0C866df7265bd3E25DA596b27;
        vm.prank(operatorFromReport);

        vm.recordLogs();

        conceroRouter.submitMessageReport(reportSubmission, messageBodies, indexes);

        vm.resumeGasMetering();

        // // Verify expected events were emitted
        // Vm.Log[] memory entries = vm.getRecordedLogs();
        // bool foundReceivedEvent = false;
        // bool foundDeliveredEvent = false;

        // for (uint256 i = 0; i < entries.length; i++) {
        //     if (entries[i].topics[0] == keccak256("ConceroMessageReceived(bytes32)")) {
        //         foundReceivedEvent = true;
        //     }
        //     if (entries[i].topics[0] == keccak256("ConceroMessageDelivered(bytes32)")) {
        //         foundDeliveredEvent = true;
        //     }
        // }

        // assertTrue(foundReceivedEvent, "ConceroMessageReceived event not emitted");
        // assertTrue(foundDeliveredEvent, "ConceroMessageDelivered event not emitted");
    }

    function test_submitMessageReport_RevertsIfNativeUsdRateIsZero() public {
        // Set nativeUsdRate to 0
        vm.startPrank(feedUpdater);
        conceroPriceFeed.setNativeUsdRate(0);
        vm.stopPrank();

        // Create a basic message report
        Types.EvmDstChainData memory dstChainData = Types.EvmDstChainData({
            receiver: address(conceroClient),
            gasLimit: GAS_LIMIT
        });

        CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
            resultType: CommonTypes.ResultType.Message,
            payloadVersion: 1,
            requester: operator
        });

        bytes[] memory allowedOperators = new bytes[](1);
        allowedOperators[0] = abi.encode(operator);

        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = CommonTypes.MessagePayloadV1({
            messageId: TEST_MESSAGE_ID,
            messageHashSum: keccak256(TEST_MESSAGE),
            messageSender: abi.encode(address(this)),
            srcChainSelector: SRC_CHAIN_SELECTOR,
            dstChainSelector: 1,
            srcBlockNumber: block.number,
            dstChainData: dstChainData,
            allowedOperators: allowedOperators
        });

        bytes memory payload = abi.encode(messagePayloadV1);
        Types.ClfDonReportSubmission memory reportSubmission = messageReport.createMockClfReport(
            abi.encode(resultConfig, payload)
        );

        bytes[] memory messageBodies = new bytes[](1);
        messageBodies[0] = TEST_MESSAGE;
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = 0;

        vm.expectRevert(
            abi.encodeWithSelector(
                CommonErrors.RequiredVariableUnset.selector,
                CommonErrors.RequiredVariableUnsetType.NativeUSDRate
            )
        );

        vm.prank(operator);
        conceroRouter.submitMessageReport(reportSubmission, messageBodies, indexes);
    }

    function test_submitMessageReport_RevertsIfLastGasPriceIsZero() public {
        // Set lastGasPrice to 0 for current chain
        vm.startPrank(feedUpdater);
        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = SRC_CHAIN_SELECTOR;
        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = 0;

        conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);
        vm.stopPrank();

        // Create a basic message report
        Types.EvmDstChainData memory dstChainData = Types.EvmDstChainData({
            receiver: address(conceroClient),
            gasLimit: GAS_LIMIT
        });

        CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
            resultType: CommonTypes.ResultType.Message,
            payloadVersion: 1,
            requester: operator
        });

        bytes[] memory allowedOperators = new bytes[](1);
        allowedOperators[0] = abi.encode(operator);

        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = CommonTypes.MessagePayloadV1({
            messageId: TEST_MESSAGE_ID,
            messageHashSum: keccak256(TEST_MESSAGE),
            messageSender: abi.encode(address(this)),
            srcChainSelector: SRC_CHAIN_SELECTOR,
            dstChainSelector: 1,
            srcBlockNumber: block.number,
            dstChainData: dstChainData,
            allowedOperators: allowedOperators
        });

        bytes memory payload = abi.encode(messagePayloadV1);
        Types.ClfDonReportSubmission memory reportSubmission = messageReport.createMockClfReport(
            abi.encode(resultConfig, payload)
        );

        bytes[] memory messageBodies = new bytes[](1);
        messageBodies[0] = TEST_MESSAGE;
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = 0;

        vm.expectRevert(
            abi.encodeWithSelector(
                CommonErrors.RequiredVariableUnset.selector,
                CommonErrors.RequiredVariableUnsetType.lastGasPrice
            )
        );

        vm.prank(operator);
        conceroRouter.submitMessageReport(reportSubmission, messageBodies, indexes);
    }

    function test_submitMessageReport_RevertsIfGasFeeNativeIsZero() public {
        vm.startPrank(deployer);
        conceroRouter.setGasFeeConfig(
            SRC_CHAIN_SELECTOR,
            0, // submitMsgGasOverhead = 0
            VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD,
            CLF_CALLBACK_GAS_OVERHEAD
        );
        vm.stopPrank();

        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = SRC_CHAIN_SELECTOR;
        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = 1;

		vm.startPrank(feedUpdater);
        conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);
		conceroPriceFeed.setNativeUsdRate(1);
		vm.stopPrank();

        Types.EvmDstChainData memory dstChainData = Types.EvmDstChainData({
            receiver: address(conceroClient),
            gasLimit: 10000
        });

        CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
            resultType: CommonTypes.ResultType.Message,
            payloadVersion: 1,
            requester: operator
        });

        bytes[] memory allowedOperators = new bytes[](1);
        allowedOperators[0] = abi.encode(operator);

        CommonTypes.MessagePayloadV1 memory messagePayloadV1 = CommonTypes.MessagePayloadV1({
            messageId: TEST_MESSAGE_ID,
            messageHashSum: keccak256(TEST_MESSAGE),
            messageSender: abi.encode(address(this)),
            srcChainSelector: SRC_CHAIN_SELECTOR,
            dstChainSelector: 1,
            srcBlockNumber: block.number,
            dstChainData: dstChainData,
            allowedOperators: allowedOperators
        });

        bytes memory payload = abi.encode(messagePayloadV1);
        Types.ClfDonReportSubmission memory reportSubmission = messageReport.createMockClfReport(
            abi.encode(resultConfig, payload)
        );

        bytes[] memory messageBodies = new bytes[](1);
        messageBodies[0] = TEST_MESSAGE;
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = 0;

        vm.expectRevert(abi.encodeWithSelector(CommonErrors.InvalidAmount.selector));

        vm.prank(operator);
        conceroRouter.submitMessageReport(reportSubmission, messageBodies, indexes);
    }

    // function testRevert_MessageAlreadyProcessed() public {
    //     // Create the payload for a message
    //     CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
    //         resultType: CommonTypes.ResultType.Message,
    //         payloadVersion: 1,
    //         requester: operator
    //     });

    //     Types.EvmDstChainData memory dstChainData = Types.EvmDstChainData({
    //         receiver: mockReceiver,
    //         gasLimit: GAS_LIMIT
    //     });

    //     bytes[] memory allowedOperators = new bytes[](1);
    //     allowedOperators[0] = abi.encode(operator);

    //     CommonTypes.MessagePayloadV1 memory messagePayload = CommonTypes.MessagePayloadV1({
    //         messageId: TEST_MESSAGE_ID,
    //         messageHashSum: keccak256(TEST_MESSAGE),
    //         messageSender: abi.encode(address(this)),
    //         srcChainSelector: SRC_CHAIN_SELECTOR,
    //         dstChainSelector: DST_CHAIN_SELECTOR,
    //         srcBlockNumber: block.number,
    //         dstChainData: dstChainData,
    //         allowedOperators: allowedOperators
    //     });

    //     bytes memory payload = abi.encode(messagePayload);
    //     bytes memory result = abi.encode(resultConfig, payload);

    //     Types.ClfDonReportSubmission memory reportSubmission = messageReport.createMockClfReport(
    //         result
    //     );

    //     bytes[] memory messageBodies = new bytes[](1);
    //     messageBodies[0] = TEST_MESSAGE;

    //     uint256[] memory indexes = new uint256[](1);
    //     indexes[0] = 0;

    //     // Set up the message as already processed
    //     vm.store(
    //         address(conceroRouter),
    //         keccak256(abi.encode(TEST_MESSAGE_ID, RouterSlots.isMessageProcessed, Namespaces.ROUTER)),
    //         bytes32(uint256(1))
    //     );

    //     vm.expectRevert(
    //         abi.encodeWithSelector(Errors.MessageAlreadyProcessed.selector, TEST_MESSAGE_ID)
    //     );
    //     conceroRouter.submitMessageReport(reportSubmission, messageBodies, indexes);
    // }

    // function testRevert_InvalidMessageHashSum() public {
    //     // Create the payload for a message with an invalid hash
    //     CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
    //         resultType: CommonTypes.ResultType.Message,
    //         payloadVersion: 1,
    //         requester: operator
    //     });

    //     Types.EvmDstChainData memory dstChainData = Types.EvmDstChainData({
    //         receiver: mockReceiver,
    //         gasLimit: GAS_LIMIT
    //     });

    //     bytes[] memory allowedOperators = new bytes[](1);
    //     allowedOperators[0] = abi.encode(operator);

    //     CommonTypes.MessagePayloadV1 memory messagePayload = CommonTypes.MessagePayloadV1({
    //         messageId: TEST_MESSAGE_ID,
    //         messageHashSum: bytes32(0), // Invalid hash
    //         messageSender: abi.encode(address(this)),
    //         srcChainSelector: SRC_CHAIN_SELECTOR,
    //         dstChainSelector: i_chainSelector,
    //         srcBlockNumber: block.number,
    //         dstChainData: dstChainData,
    //         allowedOperators: allowedOperators
    //     });

    //     bytes memory payload = abi.encode(messagePayload);
    //     bytes memory result = abi.encode(resultConfig, payload);

    //     Types.ClfDonReportSubmission memory reportSubmission = messageReport.createMockClfReport(
    //         result
    //     );

    //     bytes[] memory messageBodies = new bytes[](1);
    //     messageBodies[0] = TEST_MESSAGE;

    //     uint256[] memory indexes = new uint256[](1);
    //     indexes[0] = 0;

    //     vm.expectRevert(Errors.InvalidMessageHashSum.selector);
    //     conceroRouter.submitMessageReport(reportSubmission, messageBodies, indexes);
    // }
}
