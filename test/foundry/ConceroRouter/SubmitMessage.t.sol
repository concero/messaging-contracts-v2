// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Vm} from "forge-std/src/Vm.sol";
import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {IConceroClient} from "contracts/interfaces/IConceroClient.sol";
import {IRelayer} from "contracts/interfaces/IRelayer.sol";
import {MessageCodec} from "contracts/common/libraries/MessageCodec.sol";
import {ConceroRouter} from "contracts/ConceroRouter/ConceroRouter.sol";
import {ConceroTestClient} from "../ConceroTestClient/ConceroTestClient.sol";
import {MockConceroValidatorLib} from "../mocks/MockConceroValidatorLib.sol";

contract SubmitMessage is ConceroRouterTest {
    function test_submitMessage_gas() public {
        vm.pauseGasMetering();

        (, bytes memory messageReceipt) = _conceroSend();

        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        vm.resumeGasMetering();
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);
    }

    function test_submitMessage_Success() public {
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();

        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        vm.expectEmit(true, false, false, false);
        emit IConceroRouter.ConceroMessageDelivered(messageId);

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);
    }

    function test_submitMessage_RevertsIfInvalidDstChainSelector() public {
        (, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](0);

        vm.expectRevert(
            abi.encodeWithSelector(
                IRelayer.InvalidDstChainSelector.selector,
                this.decodeDstChainSelector(messageReceipt),
                SRC_CHAIN_SELECTOR
            )
        );

        vm.prank(s_relayer);
        s_conceroRouter.submitMessage(messageReceipt, validations, new address[](0), s_relayerLib);
    }

    function test_submitMessage_RevertsIfInvalidValidationsCount() public {
        (, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](1);
        address[] memory validatorLibs = new address[](0);

        vm.expectRevert(
            abi.encodeWithSelector(
                IRelayer.InvalidValidationsCount.selector,
                validatorLibs.length,
                validations.length
            )
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);
    }

    function test_submitMessage_RevertsIfMessageAlreadyProcessed() public {
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

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);
    }

    function test_submitMessage_RevertsIfMessageSubmissionAlreadyProcessed() public {
        (, bytes memory messageReceipt) = _conceroSend();

        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        bytes32 messageSubmissionHash = keccak256(
            abi.encode(messageReceipt, s_relayerLib, validatorLibs, validationChecks)
        );

        s_conceroClient.setRevertFlag(true);

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);

        vm.expectRevert(
            abi.encodeWithSelector(
                IRelayer.MessageSubmissionAlreadyProcessed.selector,
                messageSubmissionHash
            )
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);
    }

    function test_submitMessage_EmitsConceroMessageReceived() public {
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);
        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        vm.expectEmit(true, false, false, true);
        emit IConceroRouter.ConceroMessageReceived(
            messageId,
            messageReceipt,
            validations,
            validatorLibs,
            validationChecks,
            s_relayerLib
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);
    }

    function test_submitMessage_EmitsConceroMessageDelivered() public {
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        vm.expectEmit(true, false, false, false);
        emit IConceroRouter.ConceroMessageDelivered(messageId);

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);
    }

    function test_submitMessage_EmitsConceroMessageDeliveryFailed() public {
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();

        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        s_conceroClient.setRevertFlag(true);

        vm.expectEmit(true, false, false, true);
        emit IConceroRouter.ConceroMessageDeliveryFailed(
            messageId,
            abi.encodeWithSelector(ConceroTestClient.TestRevert.selector)
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);
    }

    function test_submitMessage_validationChecks_EmptyValidation() public {
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](1);
        validations[0] = ""; // Empty validation

        bool[] memory expectedValidationChecks = new bool[](1);
        expectedValidationChecks[0] = false;

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        vm.expectEmit(true, false, false, true);
        emit IConceroRouter.ConceroMessageReceived(
            messageId,
            messageReceipt,
            validations,
            validatorLibs,
            expectedValidationChecks,
            s_relayerLib
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);
    }

    function test_submitMessage_validationChecks_ValidatorReturnsZero() public {
        MockConceroValidatorLib(s_validatorLib).setBehavior(
            MockConceroValidatorLib.ValidationBehavior.ReturnFalse
        );

        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        bool[] memory expectedValidationChecks = new bool[](1);
        expectedValidationChecks[0] = false;

        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        vm.expectEmit(true, false, false, true);
        emit IConceroRouter.ConceroMessageReceived(
            messageId,
            messageReceipt,
            validations,
            validatorLibs,
            expectedValidationChecks,
            s_relayerLib
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations, validatorLibs, s_relayerLib);
    }

    function test_submitMessage_validationChecks_ValidatorReverts() public {
        MockConceroValidatorLib(s_validatorLib).setBehavior(
            MockConceroValidatorLib.ValidationBehavior.Revert
        );

        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        bool[] memory expectedValidationChecks = new bool[](1);
        expectedValidationChecks[0] = false;

        vm.expectEmit(true, false, false, true);
        emit IConceroRouter.ConceroMessageReceived(
            messageId,
            messageReceipt,
            validations,
            new address[](1),
            expectedValidationChecks,
            s_relayerLib
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(
            messageReceipt,
            validations,
            new address[](1),
            s_relayerLib
        );
    }

    function test_submitMessage_validationChecks_ValidatorInvalidReturnLength() public {
        MockConceroValidatorLib(s_validatorLib).setBehavior(
            MockConceroValidatorLib.ValidationBehavior.InvalidLength
        );

        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        bool[] memory expectedValidationChecks = new bool[](1);
        expectedValidationChecks[0] = false;

        vm.expectEmit(true, false, false, true);
        emit IConceroRouter.ConceroMessageReceived(
            messageId,
            messageReceipt,
            validations,
            new address[](1),
            expectedValidationChecks,
            s_relayerLib
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(
            messageReceipt,
            validations,
            new address[](1),
            s_relayerLib
        );
    }

    function test_submitMessage_RevertsDuplicateValidatorLibs() public {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();

        address[] memory dstValidatorLibs = new address[](2);
        dstValidatorLibs[0] = s_validatorLib;
        dstValidatorLibs[1] = s_validatorLib; // same validator library

        bytes[] memory dstValidatorConfigs = new bytes[](2);
        dstValidatorConfigs[0] = new bytes(0);
        dstValidatorConfigs[1] = new bytes(0);

        messageRequest.validatorLibs = dstValidatorLibs;
        messageRequest.validatorConfigs = dstValidatorConfigs;

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        vm.recordLogs();
        vm.prank(s_user);
        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes memory messageReceipt = abi.decode(entries[0].data, (bytes));

        bytes[] memory validations = new bytes[](2);
        validations[0] = abi.encode(true);
        validations[1] = abi.encode(true);

        vm.expectRevert(
            abi.encodeWithSelector(IRelayer.DuplicateValidatorLib.selector, s_validatorLib)
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(
            messageReceipt,
            validations,
            dstValidatorLibs,
            s_relayerLib
        );
    }

    function decodeDstChainSelector(bytes calldata messageReceipt) external pure returns (uint24) {
        return MessageCodec.dstChainSelector(messageReceipt);
    }
}
