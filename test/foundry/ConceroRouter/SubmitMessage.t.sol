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
import {IConceroClient} from "contracts/interfaces/IConceroClient.sol";
import {IRelayer} from "contracts/interfaces/IRelayer.sol";
import {MessageCodec} from "contracts/common/libraries/MessageCodec.sol";
import {ConceroRouter} from "contracts/ConceroRouter/ConceroRouter.sol";
import {ConceroTestClient} from "../ConceroTestClient/ConceroTestClient.sol";
import {MockConceroValidatorLib} from "../mocks/MockConceroValidatorLib.sol";

contract SubmitMessage is ConceroRouterTest {
    function setUp() public override {
        super.setUp();
    }

    function test_submitMessage_Success() public {
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();

        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        vm.expectEmit(true, false, false, false);
        emit IConceroRouter.ConceroMessageDelivered(messageId);

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations);
    }

    function test_submitMessage_RevertsIfInvalidDstChainSelector() public {
        (, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](0);

        vm.expectRevert(
            abi.encodeWithSelector(
                IRelayer.InvalidDstChainSelector.selector,
                MessageCodec.dstChainSelector(messageReceipt),
                SRC_CHAIN_SELECTOR
            )
        );

        vm.prank(s_relayer);
        s_conceroRouter.submitMessage(messageReceipt, validations);
    }

    function test_submitMessage_RevertsIfInvalidValidationsCount() public {
        (, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](0);

        vm.expectRevert(
            abi.encodeWithSelector(
                ConceroRouter.InvalidValidationsCount.selector,
                1,
                validations.length
            )
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations);
    }

    function test_submitMessage_RevertsIfMessageAlreadyProcessed() public {
        (, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations);

        vm.expectRevert(
            abi.encodeWithSelector(
                ConceroRouter.MessageAlreadyProcessed.selector,
                keccak256(messageReceipt)
            )
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations);
    }

    function test_submitMessage_RevertsIfMessageSubmissionAlreadyProcessed() public {
        (, bytes memory messageReceipt) = _conceroSend();

        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        bytes32 messageSubmissionHash = keccak256(abi.encode(messageReceipt, validationChecks));

        s_conceroClient.setRevertFlag(true);

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations);

        vm.expectRevert(
            abi.encodeWithSelector(
                ConceroRouter.MessageSubmissionAlreadyProcessed.selector,
                messageSubmissionHash
            )
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations);
    }

    function test_submitMessage_EmitsConceroMessageReceived() public {
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);
        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        vm.expectEmit(true, false, false, true);
        emit IConceroRouter.ConceroMessageReceived(
            messageId,
            messageReceipt,
            validations,
            validationChecks
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations);
    }

    function test_submitMessage_EmitsConceroMessageDelivered() public {
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        vm.expectEmit(true, false, false, false);
        emit IConceroRouter.ConceroMessageDelivered(messageId);

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations);
    }

    function test_submitMessage_EmitsConceroMessageDeliveryFailed() public {
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();

        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        bool[] memory validationChecks = new bool[](1);
        validationChecks[0] = true;

        s_conceroClient.setRevertFlag(true);

        vm.expectEmit(true, false, false, true);
        emit IConceroRouter.ConceroMessageDeliveryFailed(
            messageId,
            abi.encodeWithSelector(ConceroTestClient.TestRevert.selector)
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations);
    }

    function test_submitMessage_RevertsIfRelayerNotAllowed() public {
        (, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(true);

        s_conceroClient.setIsRelayerAllowed(s_relayerLib, false);

        vm.expectRevert(
            abi.encodeWithSelector(IConceroClient.RelayerNotAllowed.selector, s_relayerLib)
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations);
    }

    function test_submitMessage_validationChecks_EmptyValidation() public {
        (bytes32 messageId, bytes memory messageReceipt) = _conceroSend();
        bytes[] memory validations = new bytes[](1);
        validations[0] = ""; // Empty validation

        bool[] memory expectedValidationChecks = new bool[](1);
        expectedValidationChecks[0] = false;

        vm.expectEmit(true, false, false, true);
        emit IConceroRouter.ConceroMessageReceived(
            messageId,
            messageReceipt,
            validations,
            expectedValidationChecks
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations);
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

        vm.expectEmit(true, false, false, true);
        emit IConceroRouter.ConceroMessageReceived(
            messageId,
            messageReceipt,
            validations,
            expectedValidationChecks
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations);
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
            expectedValidationChecks
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations);
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
            expectedValidationChecks
        );

        vm.prank(s_relayer);
        s_dstConceroRouter.submitMessage(messageReceipt, validations);
    }
}
