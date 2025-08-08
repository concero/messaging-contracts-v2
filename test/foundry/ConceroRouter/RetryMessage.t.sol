// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";

import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {IConceroClient} from "contracts/interfaces/IConceroClient.sol";
import {ConceroMessageReceived, ConceroMessageDelivered, MessageDeliveryFailed} from "contracts/interfaces/IConceroRouter.sol";
import {ConceroClientRevertMock, ErrorType} from "contracts/mocks/ConceroClientRevertMock.sol";

import {MessageReport} from "../scripts/MockCLFReport/MessageReport.sol";

import {Storage as s, Namespaces} from "contracts/ConceroRouter/libraries/Storage.sol";
import {RouterSlots} from "contracts/ConceroRouter/libraries/StorageSlots.sol";
import {Types} from "contracts/ConceroRouter/libraries/Types.sol";
import {Errors} from "contracts/ConceroRouter/modules/Message.sol";

contract RetryMessage is ConceroRouterTest {
    bytes32 internal constant TEST_MESSAGE_ID = bytes32(uint256(1));
    uint256 internal constant GAS_LIMIT = 100_000;

    uint256[] public indexes = new uint256[](1);

    MessageReport internal messageReport;
    ConceroClientRevertMock internal conceroClientRevert;

    function setUp() public override {
        super.setUp();
        messageReport = new MessageReport();

        _setPriceFeeds();
        conceroClientRevert = new ConceroClientRevertMock(address(conceroRouter));
        indexes[0] = 0; // Only one message in the report
    }

    // --- Tests for deliverMessage function ---

    function test_deliverMessage_SetStatusReceived() public {
        uint8 errorType = uint8(ErrorType.OutOfGasRevert);
        bytes memory message = abi.encode(errorType); // requires more gas than GAS_LIMIT

        bytes memory callData = _getCallData(message);
        bytes32 messageHash = _hash(TEST_MESSAGE_ID, address(conceroClientRevert), callData);

        _submitMessageReport(message);

        assertEq(
            conceroRouter.getStorage(Namespaces.ROUTER, RouterSlots.messageStatus, messageHash),
            uint8(s.Status.Received),
            "Storage getter failed for messageStatus"
        );
    }

    function test_deliverMessage_EmitConceroMessageReceived() public {
        uint8 errorType = uint8(ErrorType.OutOfGasRevert);
        bytes memory message = abi.encode(errorType);

        Types.ClfDonReportSubmission memory reportSubmission = _receiveMessage(message);

        vm.expectEmit(true, false, false, false);
        emit ConceroMessageReceived(TEST_MESSAGE_ID);

        bytes[] memory messages = new bytes[](1);
        messages[0] = message;

        vm.prank(operator);
        conceroRouter.submitMessageReport(reportSubmission, messages, indexes);
    }

    function test_deliverMessage_EmitConceroMessageDelivered() public {
        uint8 errorType = uint8(ErrorType.OutOfGasRevert);
        bytes memory message = abi.encode(errorType);

        Types.ClfDonReportSubmission memory reportSubmission = _receiveMessage(message);

        conceroClientRevert.setRevertMode(false);

        vm.expectEmit(true, false, false, false);
        emit ConceroMessageDelivered(TEST_MESSAGE_ID);

        bytes[] memory messages = new bytes[](1);
        messages[0] = message;

        vm.prank(operator);
        conceroRouter.submitMessageReport(reportSubmission, messages, indexes);
    }

    function test_deliverMessage_EmitMessageDeliveryFailed_EmptyError() public {
        bytes memory message = abi.encode(uint8(ErrorType.EmptyRevert));

        Types.ClfDonReportSubmission memory reportSubmission = _receiveMessage(message);

        bytes memory emptyError; // 0x

        vm.expectEmit(true, false, false, true);
        emit MessageDeliveryFailed(TEST_MESSAGE_ID, emptyError);

        bytes[] memory messages = new bytes[](1);
        messages[0] = message;

        vm.prank(operator);
        conceroRouter.submitMessageReport(reportSubmission, messages, indexes);
    }

    function test_deliverMessage_EmitMessageDeliveryFailed_OutOfGas() public {
        bytes memory message = abi.encode(uint8(ErrorType.OutOfGasRevert));

        Types.ClfDonReportSubmission memory reportSubmission = _receiveMessage(message);

        bytes memory outOfGasError; // 0x (OutOfGas)
        vm.expectEmit(true, false, false, true);
        emit MessageDeliveryFailed(TEST_MESSAGE_ID, outOfGasError);

        bytes[] memory messages = new bytes[](1);
        messages[0] = message;

        vm.prank(operator);
        conceroRouter.submitMessageReport(reportSubmission, messages, indexes);
    }

    function test_deliverMessage_EmitMessageDeliveryFailed_StringRevert() public {
        bytes memory message = abi.encode(uint8(ErrorType.StringRevert));

        Types.ClfDonReportSubmission memory reportSubmission = _receiveMessage(message);

        string memory errorMessage = "ConceroClientRevertMock: String revert message";
        bytes memory stringRevert = abi.encodeWithSignature("Error(string)", errorMessage);
        vm.expectEmit(true, false, false, true);
        emit MessageDeliveryFailed(TEST_MESSAGE_ID, stringRevert);

        bytes[] memory messages = new bytes[](1);
        messages[0] = message;

        vm.prank(operator);
        conceroRouter.submitMessageReport(reportSubmission, messages, indexes);
    }

    function test_deliverMessage_EmitMessageDeliveryFailed_PanicRevert() public {
        bytes memory message = abi.encode(uint8(ErrorType.PanicRevert));

        Types.ClfDonReportSubmission memory reportSubmission = _receiveMessage(message);

        bytes memory panicRevert = abi.encodeWithSignature("Panic(uint256)", 0x1);
        vm.expectEmit(true, false, false, true);
        emit MessageDeliveryFailed(TEST_MESSAGE_ID, panicRevert);

        bytes[] memory messages = new bytes[](1);
        messages[0] = message;

        vm.prank(operator);
        conceroRouter.submitMessageReport(reportSubmission, messages, indexes);
    }

    function test_deliverMessage_EmitMessageDeliveryFailed_CustomErrorRevert() public {
        bytes memory message = abi.encode(uint8(ErrorType.CustomErrorRevert));

        Types.ClfDonReportSubmission memory reportSubmission = _receiveMessage(message);

        uint256 errorCode = 42;
        string memory errorMessage = "Custom error with parameters";
        bytes memory customErrorRevert = abi.encodeWithSignature(
            "CustomConceroError(uint256,string)",
            errorCode,
            errorMessage
        );
        vm.expectEmit(true, false, false, true);
        emit MessageDeliveryFailed(TEST_MESSAGE_ID, customErrorRevert);

        bytes[] memory messages = new bytes[](1);
        messages[0] = message;

        vm.prank(operator);
        conceroRouter.submitMessageReport(reportSubmission, messages, indexes);
    }

    // --- Tests for retry function ---

    function test_retry_SetStatusDelivered() public {
        uint8 errorType = uint8(ErrorType.OutOfGasRevert);
        bytes memory message = abi.encode(errorType);
        bytes memory callData = _getCallData(message);
        bytes32 messageHash = _hash(TEST_MESSAGE_ID, address(conceroClientRevert), callData);

        _submitMessageReport(message);

        conceroClientRevert.setRevertMode(false);

        conceroRouter.retry(TEST_MESSAGE_ID, address(conceroClientRevert), GAS_LIMIT, callData);

        assertEq(
            conceroRouter.getStorage(Namespaces.ROUTER, RouterSlots.messageStatus, messageHash),
            uint8(s.Status.Delivered),
            "Storage getter failed for messageStatus"
        );
    }

    function test_retry_RevertIfMessageAlreadyDelivered() public {
        uint8 errorType = uint8(ErrorType.OutOfGasRevert);
        bytes memory message = abi.encode(errorType);
        bytes memory callData = _getCallData(message);

        _submitMessageReport(message);

        conceroClientRevert.setRevertMode(false);

        conceroRouter.retry(TEST_MESSAGE_ID, address(conceroClientRevert), GAS_LIMIT, callData);

        vm.expectRevert(abi.encodeWithSelector(Errors.MessageAlreadyDelivered.selector));

        conceroRouter.retry(TEST_MESSAGE_ID, address(conceroClientRevert), GAS_LIMIT, callData);
    }

    function test_retry_RevertIfUnknownMessage() public {
        bytes memory callData;

        vm.expectRevert(abi.encodeWithSelector(Errors.UnknownMessage.selector));

        conceroRouter.retry(TEST_MESSAGE_ID, address(conceroClientRevert), GAS_LIMIT, callData);
    }

    function test_retry_RevertIfMessageDeliveryFailed() public {
        uint8 errorType = uint8(ErrorType.OutOfGasRevert);
        bytes memory message = abi.encode(errorType);
        bytes memory callData = _getCallData(message);

        _submitMessageReport(message);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.ManualMessageDeliveryFailed.selector, TEST_MESSAGE_ID)
        );

        conceroRouter.retry(TEST_MESSAGE_ID, address(conceroClientRevert), GAS_LIMIT, callData);
    }

    function test_retry_EmitConceroMessageDelivered() public {
        uint8 errorType = uint8(ErrorType.OutOfGasRevert);
        bytes memory message = abi.encode(errorType);
        bytes memory callData = _getCallData(message);

        _submitMessageReport(message);

        conceroClientRevert.setRevertMode(false);

        vm.expectEmit(true, false, false, false);
        emit ConceroMessageDelivered(TEST_MESSAGE_ID);

        conceroRouter.retry(TEST_MESSAGE_ID, address(conceroClientRevert), GAS_LIMIT, callData);
    }

    // --- Helper functions ---

    function _receiveMessage(
        bytes memory receivedMessage
    ) private view returns (Types.ClfDonReportSubmission memory reportSubmission) {
        Types.EvmDstChainData memory dstChainData = Types.EvmDstChainData({
            receiver: address(conceroClientRevert),
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
            messageHashSum: keccak256(receivedMessage),
            txHash: bytes32(0),
            messageSender: abi.encode(address(this)),
            srcChainSelector: SRC_CHAIN_SELECTOR,
            dstChainSelector: 1,
            srcBlockNumber: 0,
            dstChainData: dstChainData,
            allowedOperators: allowedOperators
        });

        bytes memory payload = abi.encode(messagePayloadV1);

        reportSubmission = messageReport.createMockClfReport(abi.encode(resultConfig, payload));
    }

    function _hash(
        bytes32 messageId,
        address receiver,
        bytes memory data
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(messageId, receiver, keccak256(data)));
    }

    function _getCallData(bytes memory message) private view returns (bytes memory callData) {
        callData = abi.encodeWithSelector(
            IConceroClient.conceroReceive.selector,
            TEST_MESSAGE_ID,
            SRC_CHAIN_SELECTOR,
            abi.encode(address(this)),
            message
        );
    }

    function _submitMessageReport(
        bytes memory message
    ) private returns (Types.ClfDonReportSubmission memory reportSubmission) {
        reportSubmission = _receiveMessage(message);

        bytes[] memory messages = new bytes[](1);
        messages[0] = message;

        vm.prank(operator);
        conceroRouter.submitMessageReport(reportSubmission, messages, indexes);

        return reportSubmission;
    }
}
