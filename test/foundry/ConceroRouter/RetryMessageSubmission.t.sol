// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/console.sol";
import {Vm} from "forge-std/src/Vm.sol";

import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {IRelayer} from "contracts/interfaces/IRelayer.sol";
import {ConceroRouter} from "contracts/ConceroRouter/ConceroRouter.sol";
import {ConceroTestClient} from "../ConceroTestClient/ConceroTestClient.sol";
import {ConceroTestClientAdvanced} from "../ConceroTestClient/ConceroTestClientAdvanced.sol";
import {MessageCodec} from "contracts/common/libraries/MessageCodec.sol";
import {MockConceroValidatorLib} from "../mocks/MockConceroValidatorLib.sol";

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
                IRelayer.MessageAlreadyProcessed.selector,
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
        bytes32 messageSubmissionHash = keccak256(
            abi.encode(messageReceipt, s_relayerLib, validatorLibs, validationChecks)
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IRelayer.MessageSubmissionAlreadyProcessed.selector,
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

    /**
     * @notice This test checks that the router cannot retry a message
     *         when the validator libs order is different
     * @dev Let's assume
     *      - s_validatorLib has weight 1
     *      - validatorLib2 has weight 2
     *      - required weight is 2
     *      - the message is submitted with the right order of validator libs
     *        but the second validator returns false, the message should be retried
     *      - malicious actor swaps the validator libs order and tries to retry the message
     *      - the router should revert because the submission hash is different
     */
    function test_retryMessageSubmission_CannotRetryWhenValidatorLibsOrderIsDifferent() public {
        // 1. Create a second validator library with weights
        address validatorLib2 = address(new MockConceroValidatorLib());

        ConceroTestClientAdvanced s_advancedConceroClient = new ConceroTestClientAdvanced(
            payable(address(s_dstConceroRouter))
        );

        // 2. Set the weights and required weight for each validator
        // s_validatorLib has weight 1
        // validatorLib2 has weight 2
        // required weight is 2
        s_advancedConceroClient.setValidatorWeight(s_validatorLib, 1);
        s_advancedConceroClient.setValidatorWeight(validatorLib2, 2);
        s_advancedConceroClient.setRequiredWeight(2);
        s_advancedConceroClient.setIsRelayerLibAllowed(s_relayerLib, true);

        address[] memory validatorLibs = new address[](2);
        validatorLibs[0] = s_validatorLib;
        validatorLibs[1] = validatorLib2;

        bytes[] memory validatorConfigs = new bytes[](2);
        validatorConfigs[0] = new bytes(0);
        validatorConfigs[1] = new bytes(0);

        bytes memory dstChainData = MessageCodec.encodeEvmDstChainData(
            address(s_advancedConceroClient),
            SUBMIT_MSG_GAS_OVERHEAD
        );

        // 3. Prepare the messageRequest
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();
        messageRequest.dstChainData = dstChainData;
        messageRequest.validatorLibs = validatorLibs;
        messageRequest.validatorConfigs = validatorConfigs;

        // 4. Send the message
        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        vm.recordLogs();
        vm.prank(s_user);
        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes memory messageReceipt = abi.decode(entries[0].data, (bytes));

        // 5. Second validator will return false
        // It means that the message is not valid and should be retried
        // Because the second validator has more weight than the first one
        MockConceroValidatorLib(validatorLib2).setBehavior(
            MockConceroValidatorLib.ValidationBehavior.ReturnFalse
        );

        bytes[] memory validations = new bytes[](2);
        validations[0] = abi.encode(true);
        validations[1] = abi.encode(false);

        // 6. Submit the message with the right order of validator libs
        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);

        // 7. Let's try swapping the libraries around and make retry
        validatorLibs[0] = validatorLib2;
        validatorLibs[1] = s_validatorLib;

        bool[] memory validationChecks = new bool[](2);
        validationChecks[0] = true;
        validationChecks[1] = false;

        bytes32 messageSubmissionHash = keccak256(
            abi.encode(messageReceipt, s_relayerLib, validatorLibs, validationChecks)
        );

        // Should revert because the submission hash is different
        vm.expectRevert(
            abi.encodeWithSelector(
                IRelayer.MessageSubmissionAlreadyProcessed.selector,
                messageSubmissionHash
            )
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.retryMessageSubmission(
            messageReceipt,
            validationChecks,
            validatorLibs,
            s_relayerLib,
            SUBMIT_MSG_GAS_OVERHEAD
        );
    }

    // HELPERS

    function decodeEvmDstChainData(
        bytes calldata messageReceipt
    ) external pure returns (address, uint32) {
        return MessageCodec.evmDstChainData(messageReceipt);
    }
}
