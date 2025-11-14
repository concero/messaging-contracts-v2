// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/console.sol";

import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {ConceroRouter} from "contracts/ConceroRouter/ConceroRouter.sol";
import {ConceroTestClient} from "../ConceroTestClient/ConceroTestClient.sol";
import {MessageCodec} from "contracts/common/libraries/MessageCodec.sol";

contract RetryMessageSubmission is ConceroRouterTest {
    function test_retryMessageSubmission_Success() public {
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();

        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        (, uint32 gasLimit) = this.decodeEvmDstChainData(messageReceipt);

        s_conceroClient.setRevertFlag(true);

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        s_conceroClient.setRevertFlag(false);

        vm.expectEmit(true, false, false, false);
        emit IConceroRouter.ConceroMessageDelivered(messageId);

        vm.prank(s_relayerLib);
        s_dstConceroRouter.retryMessageSubmission(
            messageReceipt,
            validationChecks,
            validatorLibs,
            s_relayerLib,
            gasLimit
        );
    }

    function test_retryMessageSubmission_RevertsIfMessageAlreadyProcessed() public {
        (, bytes memory messageReceipt) = _conceroSend();

        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);

        (, uint32 gasLimit) = this.decodeEvmDstChainData(messageReceipt);

        vm.expectRevert(
            abi.encodeWithSelector(
                ConceroRouter.MessageAlreadyProcessed.selector,
                keccak256(messageReceipt)
            )
        );

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        vm.prank(s_user);
        s_dstConceroRouter.retryMessageSubmission(
            messageReceipt,
            validationChecks,
            validatorLibs,
            s_relayerLib,
            gasLimit
        );
    }

    function test_retryMessageSubmission_RevertsIfMessageSubmissionAlreadyProcessed() public {
        (, bytes memory messageReceipt) = _conceroSend();

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        (, uint32 gasLimit) = this.decodeEvmDstChainData(messageReceipt);
        bytes32 messageSubmissionHash = keccak256(abi.encode(messageReceipt, validationChecks));

        vm.expectRevert(
            abi.encodeWithSelector(
                ConceroRouter.MessageSubmissionAlreadyProcessed.selector,
                messageSubmissionHash
            )
        );

        vm.prank(s_relayerLib);
        s_dstConceroRouter.retryMessageSubmission(
            messageReceipt,
            validationChecks,
            validatorLibs,
            s_relayerLib,
            gasLimit
        );
    }

    function test_retryMessageSubmission_SequenceOfRetries() public {
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();

        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        // Set revert flag
        s_conceroClient.setRevertFlag(true);

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);

        (, uint32 gasLimit) = this.decodeEvmDstChainData(messageReceipt);

        // First retry
        vm.expectEmit(true, false, false, true);
        emit IConceroRouter.ConceroMessageDeliveryFailed(
            messageId,
            abi.encodeWithSelector(ConceroTestClient.TestRevert.selector)
        );

        vm.prank(s_user);
        s_dstConceroRouter.retryMessageSubmission(
            messageReceipt,
            validationChecks,
            validatorLibs,
            s_relayerLib,
            gasLimit
        );

        // Second retry
        vm.expectEmit(true, false, false, true);
        emit IConceroRouter.ConceroMessageDeliveryFailed(
            messageId,
            abi.encodeWithSelector(ConceroTestClient.TestRevert.selector)
        );

        vm.prank(s_user);
        s_dstConceroRouter.retryMessageSubmission(
            messageReceipt,
            validationChecks,
            validatorLibs,
            s_relayerLib,
            gasLimit
        );

        s_conceroClient.setRevertFlag(false);

        // Third retry - success
        vm.expectEmit(true, false, false, false);
        emit IConceroRouter.ConceroMessageDelivered(messageId);

        vm.prank(s_user);
        s_dstConceroRouter.retryMessageSubmission(
            messageReceipt,
            validationChecks,
            validatorLibs,
            s_relayerLib,
            gasLimit
        );
    }

    function test_retryMessageSubmission_EmitsConceroMessageDelivered() public {
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();

        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        (, uint32 gasLimit) = this.decodeEvmDstChainData(messageReceipt);

        s_conceroClient.setRevertFlag(true);
        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);

        s_conceroClient.setRevertFlag(false);

        vm.expectEmit(true, false, false, false);
        emit IConceroRouter.ConceroMessageDelivered(messageId);

        vm.prank(s_user);
        s_dstConceroRouter.retryMessageSubmission(
            messageReceipt,
            validationChecks,
            validatorLibs,
            s_relayerLib,
            gasLimit
        );
    }

    // HELPERS

    function decodeEvmDstChainData(
        bytes calldata messageReceipt
    ) external pure returns (address, uint32) {
        return MessageCodec.evmDstChainData(messageReceipt);
    }
}
