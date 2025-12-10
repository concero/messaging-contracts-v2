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
import {ValidatorCodec} from "contracts/common/libraries/ValidatorCodec.sol";

contract RetryMessageSubmission is ConceroRouterTest {
    function test_retryMessageSubmission_Success() public {
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();

        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

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
            s_relayerLib
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
            s_relayerLib
        );
    }

    function test_retryMessageSubmission_RevertsIfMessageSubmissionAlreadyProcessed() public {
        (, bytes memory messageReceipt) = _conceroSend();

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

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
            s_relayerLib
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
            s_relayerLib
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
            s_relayerLib
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
            s_relayerLib
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
            s_relayerLib
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
        (, bytes memory messageReceipt) = _conceroSend(messageRequest);

        // 5. Second validator will return false
        // It means that the message is not valid and should be retried
        // Because the second validator has more weight than the first one
        MockConceroValidatorLib(validatorLib2).setBehavior(
            MockConceroValidatorLib.ValidationBehavior.ReturnFalse
        );

        bytes[] memory validations = new bytes[](2);

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
            s_relayerLib
        );
    }

    /**
     * @notice Test to ensure that retryMessageSubmissionWithValidation behaves correctly.
     * @dev    This test uses two validator libraries.
     *         Both validator libraries are required for a successful validation.
     *         During the initial submitMessage call, one of the validators is expected to fail with an out-of-gas error.
     *         After that, retryMessageSubmissionWithValidation is called with the same arguments, and both validations are expected to succeed.
     */
    function test_retryMessageSubmissionWithValidation_Success() public {
        // 1. Create a second validator library and set it as allowed on the client
        address validatorLib2 = address(new MockConceroValidatorLib());

        s_conceroClient.setIsValidatorAllowed(validatorLib2, true);
        s_conceroClient.setRequiredValidatorsCount(2);

        // 2. Prepare the messageRequest
        address[] memory validatorLibs = new address[](2);
        validatorLibs[0] = s_validatorLib;
        validatorLibs[1] = validatorLib2;

        bytes[] memory validatorConfigs = new bytes[](2);
        validatorConfigs[0] = new bytes(0);
        validatorConfigs[1] = new bytes(0);

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();
        messageRequest.validatorLibs = validatorLibs;
        messageRequest.validatorConfigs = validatorConfigs;

        // 3. Set the validation gas limit for the second validator to 0
        MockConceroValidatorLib(validatorLib2).setValidationGasLimit(0);

        // 4. Send the message
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend(messageRequest);

        bytes[] memory validations = new bytes[](2);
        validations[0] = abi.encode(true);
        validations[1] = abi.encode(false);

        // 5. Submit the message
        // Second validator should revert with out-of-gas error
        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);

        bool[] memory validationChecks = new bool[](2);
        validationChecks[0] = true;
        validationChecks[1] = false;

        vm.expectEmit(true, false, false, false);
        emit IConceroRouter.ConceroMessageDelivered(messageId);

        // 6. Retry the message with validation
        s_dstConceroRouter.retryMessageSubmissionWithValidation(
            messageReceipt,
            validations,
            validationChecks,
            validatorLibs,
            s_relayerLib
        );
    }

    // HELPERS

    function decodeEvmDstChainData(
        bytes calldata messageReceipt
    ) external pure returns (address, uint32) {
        return MessageCodec.evmDstChainData(messageReceipt);
    }
}
