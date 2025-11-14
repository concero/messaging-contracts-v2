// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {MessageCodec} from "contracts/common/libraries/MessageCodec.sol";
import {IRelayerLib} from "contracts/interfaces/IRelayerLib.sol";
import {IValidatorLib} from "contracts/interfaces/IValidatorLib.sol";

contract SendMessage is ConceroRouterTest {
    function test_conceroSend_NativeFee_gas() public {
        vm.pauseGasMetering();

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        vm.resumeGasMetering();
        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);
    }

    function testFuzz_conceroSend_NativeFee(
        bytes memory payload,
        uint32 gasLimit,
        uint64 srcChainConfirmations
    ) public {
        vm.assume(gasLimit > 0);
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest(
            payload,
            gasLimit,
            srcChainConfirmations
        );

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);
    }

    function testFuzz_conceroSend_RevertsIfUnsupportedFeeToken(address feeToken) public {
        vm.assume(feeToken != address(0));

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest(feeToken);

        vm.expectRevert(IConceroRouter.UnsupportedFeeToken.selector);
        s_conceroRouter.getMessageFee(messageRequest);

        vm.expectRevert(IConceroRouter.UnsupportedFeeToken.selector);
        s_conceroRouter.conceroSend(messageRequest);
    }

    function test_conceroSend_RevertIfEmptyDstChainData() public {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();
        messageRequest.dstChainData = bytes("");

        vm.expectRevert(IConceroRouter.EmptyDstChainData.selector);
        s_conceroRouter.getMessageFee(messageRequest);

        vm.expectRevert(IConceroRouter.EmptyDstChainData.selector);
        s_conceroRouter.conceroSend(messageRequest);
    }

    function test_conceroSend_RevertsIfPayloadTooLarge() public {
        bytes memory payload = new bytes(s_conceroRouter.getMaxPayloadSize() + 1);

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest(payload);

        bytes memory error = abi.encodeWithSelector(
            IConceroRouter.PayloadTooLarge.selector,
            payload.length,
            s_conceroRouter.getMaxPayloadSize()
        );

        vm.expectRevert(error);
        s_conceroRouter.getMessageFee(messageRequest);

        vm.expectRevert(error);
        s_conceroRouter.conceroSend(messageRequest);
    }

    function test_conceroSend_RevertsIfInvalidValidatorsCount() public {
        address[] memory validatorLibs = new address[](s_conceroRouter.getMaxValidatorsCount() + 1);

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest(validatorLibs);
        messageRequest.validatorConfigs = new bytes[](s_conceroRouter.getMaxValidatorsCount() + 1);

        bytes memory error = abi.encodeWithSelector(
            IConceroRouter.InvalidValidatorsCount.selector,
            validatorLibs.length,
            s_conceroRouter.getMaxValidatorsCount()
        );

        vm.expectRevert(error);
        s_conceroRouter.getMessageFee(messageRequest);

        vm.expectRevert(error);
        s_conceroRouter.conceroSend(messageRequest);
    }

    function test_conceroSend_RevertsIfInvalidValidatorConfigsCount() public {
        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest(validatorLibs);
        messageRequest.validatorConfigs = new bytes[](2);

        bytes memory error = abi.encodeWithSelector(
            IConceroRouter.InvalidValidatorConfigsCount.selector,
            messageRequest.validatorConfigs.length,
            validatorLibs.length
        );

        vm.expectRevert(error);
        s_conceroRouter.getMessageFee(messageRequest);

        vm.expectRevert(error);
        s_conceroRouter.conceroSend(messageRequest);
    }

    function test_conceroSend_messageIdIsCorrect() public {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);
        bytes32 messageId = s_conceroRouter.conceroSend{value: messageFee}(messageRequest);

        uint256 nonce = 1;

        bytes memory packedMessage = MessageCodec.toMessageReceiptBytes(
            messageRequest,
            SRC_CHAIN_SELECTOR,
            address(this),
            nonce
        );

        bytes32 expectedMessageId = keccak256(packedMessage);

        assertEq(messageId, expectedMessageId);
    }

    function test_conceroSend_EmitsConceroMessageSent() public {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        uint256 nonce = 1;

        bytes memory packedMessage = MessageCodec.toMessageReceiptBytes(
            messageRequest,
            SRC_CHAIN_SELECTOR,
            address(this),
            nonce
        );

        bytes32 expectedMessageId = keccak256(packedMessage);

        vm.expectEmit(true, false, false, true);
        emit IConceroRouter.ConceroMessageSent(
            expectedMessageId,
            packedMessage,
            messageRequest.validatorLibs,
            s_relayerLib
        );

        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);
    }
}
