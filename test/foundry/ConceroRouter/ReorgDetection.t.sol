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
import {CommonConstants} from "contracts/common/CommonConstants.sol";

import {Types} from "contracts/ConceroRouter/libraries/Types.sol";
import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";
import {MessageReport as MockCLFReport} from "../scripts/MockCLFReport/MessageReport.sol";

contract ReorgDetectionTest is ConceroRouterTest {
    MockCLFReport internal mockClfReport;
    address internal mockReceiver;
    bytes32 internal constant TEST_MESSAGE_ID_1 = bytes32(uint256(1));
    bytes32 internal constant TEST_MESSAGE_ID_2 = bytes32(uint256(2));
    bytes internal constant TEST_MESSAGE_1 = "Test message 1";
    bytes internal constant TEST_MESSAGE_2 = "Test message 2";
    bytes32 internal constant TEST_TX_HASH = bytes32(uint256(0x123456789));
    uint256 internal constant GAS_LIMIT = 1_000_000;

    event MessageReorgDetected(bytes32 indexed txHash, uint24 indexed srcChainSelector);
    event ConceroMessageReceived(bytes32 indexed messageId);
    event ConceroMessageDelivered(bytes32 indexed messageId);

    function setUp() public override {
        super.setUp();
        mockClfReport = new MockCLFReport();
        mockReceiver = address(conceroClient);

        _setPriceFeeds();
    }

    function test_ReorgDetectionWithSameTxHash() public {
        // Create first message with specific txHash
        bytes memory response1 = _createMessageResponse(
            TEST_MESSAGE_ID_1,
            keccak256(TEST_MESSAGE_1),
            TEST_TX_HASH,
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            address(user),
            12345678
        );

        // Submit first message
        vm.recordLogs();
        vm.prank(operator);
        bytes[] memory messageBodies1 = new bytes[](1);
        messageBodies1[0] = TEST_MESSAGE_1;
        uint256[] memory indexes1 = new uint256[](1);
        indexes1[0] = 0;
        conceroRouter.submitMessageReport(
            mockClfReport.createMockClfReport(response1, bytes32("requestId1")),
            messageBodies1,
            indexes1
        );

        Vm.Log[] memory entries1 = vm.getRecordedLogs();

        // Verify first message was processed successfully
        bool receivedEventFound1 = false;
        bool deliveredEventFound1 = false;
        bool reorgEventFound1 = false;

        for (uint256 i = 0; i < entries1.length; i++) {
            if (entries1[i].topics[0] == keccak256("ConceroMessageReceived(bytes32)")) {
                receivedEventFound1 = true;
                assertEq(
                    entries1[i].topics[1],
                    TEST_MESSAGE_ID_1,
                    "First message: ConceroMessageReceived event has incorrect messageId"
                );
            }
            if (entries1[i].topics[0] == keccak256("ConceroMessageDelivered(bytes32)")) {
                deliveredEventFound1 = true;
                assertEq(
                    entries1[i].topics[1],
                    TEST_MESSAGE_ID_1,
                    "First message: ConceroMessageDelivered event has incorrect messageId"
                );
            }
            if (entries1[i].topics[0] == keccak256("MessageReorgDetected(bytes32,uint24)")) {
                reorgEventFound1 = true;
            }
        }

        assertTrue(receivedEventFound1, "First message: ConceroMessageReceived event not emitted");
        assertTrue(
            deliveredEventFound1,
            "First message: ConceroMessageDelivered event not emitted"
        );
        assertFalse(
            reorgEventFound1,
            "First message: Unexpected MessageReorgDetected event emitted"
        );

        // Create second message with same txHash but different content
        bytes memory response2 = _createMessageResponse(
            TEST_MESSAGE_ID_2,
            keccak256(TEST_MESSAGE_2),
            TEST_TX_HASH, // Same txHash as first message
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            address(user),
            12345679
        );

        // Submit second message with same txHash
        vm.recordLogs();
        vm.prank(operator);
        bytes[] memory messageBodies2 = new bytes[](1);
        messageBodies2[0] = TEST_MESSAGE_2;
        uint256[] memory indexes2 = new uint256[](1);
        indexes2[0] = 0;
        conceroRouter.submitMessageReport(
            mockClfReport.createMockClfReport(response2, bytes32("requestId2")),
            messageBodies2,
            indexes2
        );

        Vm.Log[] memory entries2 = vm.getRecordedLogs();

        // Verify second message triggered reorg detection
        bool receivedEventFound2 = false;
        bool deliveredEventFound2 = false;
        bool reorgEventFound2 = false;

        for (uint256 i = 0; i < entries2.length; i++) {
            if (entries2[i].topics[0] == keccak256("ConceroMessageReceived(bytes32)")) {
                receivedEventFound2 = true;
            }
            if (entries2[i].topics[0] == keccak256("ConceroMessageDelivered(bytes32)")) {
                deliveredEventFound2 = true;
            }
            if (entries2[i].topics[0] == keccak256("MessageReorgDetected(bytes32,uint24)")) {
                reorgEventFound2 = true;
                assertEq(entries2[i].topics[1], TEST_TX_HASH, "Reorg event: incorrect txHash");
                assertEq(
                    uint256(entries2[i].topics[2]),
                    uint256(SRC_CHAIN_SELECTOR),
                    "Reorg event: incorrect srcChainSelector"
                );
            }
        }

        assertFalse(
            receivedEventFound2,
            "Second message: ConceroMessageReceived should not be emitted due to reorg detection"
        );
        assertFalse(
            deliveredEventFound2,
            "Second message: ConceroMessageDelivered should not be emitted due to reorg detection"
        );
        assertTrue(
            reorgEventFound2,
            "Second message: MessageReorgDetected event should be emitted"
        );
    }

    function test_NormalProcessingWithDifferentTxHash() public {
        // Create first message
        bytes memory response1 = _createMessageResponse(
            TEST_MESSAGE_ID_1,
            keccak256(TEST_MESSAGE_1),
            bytes32(uint256(0x111)), // First txHash
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            address(user),
            12345678
        );

        // Submit first message
        vm.prank(operator);
        bytes[] memory messageBodies1 = new bytes[](1);
        messageBodies1[0] = TEST_MESSAGE_1;
        uint256[] memory indexes1 = new uint256[](1);
        indexes1[0] = 0;
        conceroRouter.submitMessageReport(
            mockClfReport.createMockClfReport(response1, bytes32("requestId1")),
            messageBodies1,
            indexes1
        );

        // Create second message with different txHash
        bytes memory response2 = _createMessageResponse(
            TEST_MESSAGE_ID_2,
            keccak256(TEST_MESSAGE_2),
            bytes32(uint256(0x222)), // Different txHash
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            address(user),
            12345679
        );

        // Submit second message
        vm.recordLogs();
        vm.prank(operator);
        bytes[] memory messageBodies2 = new bytes[](1);
        messageBodies2[0] = TEST_MESSAGE_2;
        uint256[] memory indexes2 = new uint256[](1);
        indexes2[0] = 0;
        conceroRouter.submitMessageReport(
            mockClfReport.createMockClfReport(response2, bytes32("requestId2")),
            messageBodies2,
            indexes2
        );

        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Verify both messages were processed normally
        bool receivedEventFound2 = false;
        bool reorgEventFound = false;

        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("ConceroMessageReceived(bytes32)")) {
                if (entries[i].topics[1] == TEST_MESSAGE_ID_2) {
                    receivedEventFound2 = true;
                }
            }
            if (entries[i].topics[0] == keccak256("MessageReorgDetected(bytes32,uint24)")) {
                reorgEventFound = true;
            }
        }

        assertTrue(
            receivedEventFound2,
            "Second message should be processed normally with different txHash"
        );
        assertFalse(reorgEventFound, "No reorg event should be emitted for different txHash");
    }

    function _createMessageResponse(
        bytes32 messageId,
        bytes32 messageHashSum,
        bytes32 txHash,
        uint24 srcChainSelector,
        uint24 dstChainSelector,
        address messageSender,
        uint256 srcBlockNumber
    ) internal view returns (bytes memory) {
        bytes[] memory allowedOperators = new bytes[](1);
        allowedOperators[0] = abi.encode(operator);
        return
            mockClfReport.getResponse(
                operator, // Use operator as requester to match msg.sender
                messageId,
                messageHashSum,
                txHash,
                srcChainSelector,
                dstChainSelector,
                messageSender,
                srcBlockNumber,
                Types.EvmDstChainData({receiver: mockReceiver, gasLimit: GAS_LIMIT}),
                allowedOperators
            );
    }
}
