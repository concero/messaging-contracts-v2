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

contract SendMessage is ConceroRouterTest {
    function setUp() public override {
        super.setUp();
    }

    function test_conceroSendNativeFee_gas() public {
        vm.pauseGasMetering();

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        vm.resumeGasMetering();
        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);
    }

    function testFuzz_conceroSendNativeFee(
        bytes memory payload,
        uint32 gasLimit,
        uint64 srcChainConfirmations
    ) public {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest(
            payload,
            gasLimit,
            srcChainConfirmations
        );

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);
    }

    function testFuzz_feeTokenIsNotSupported_revert(address feeToken) public {
        vm.assume(feeToken != address(0));

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest(feeToken);

        vm.expectRevert(IConceroRouter.UnsupportedFeeToken.selector);
        s_conceroRouter.getMessageFee(messageRequest);

        vm.expectRevert(IConceroRouter.UnsupportedFeeToken.selector);
        s_conceroRouter.conceroSend(messageRequest);
    }

    function test_payloadToLarge_revert() public {
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

    function test_invalidValidatorsCount_revert() public {
        address[] memory validatorLibs = new address[](s_conceroRouter.getMaxValidatorsCount() + 1);

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest(validatorLibs);

        bytes memory error = abi.encodeWithSelector(
            IConceroRouter.InvalidValidatorsCount.selector,
            validatorLibs.length,
            s_conceroRouter.getMaxValidatorsCount()
        );

        vm.expectRevert(error);
        s_conceroRouter.getMessageFee(messageRequest);

        vm.expectRevert(error);
        s_conceroRouter.conceroSend(messageRequest);

        validatorLibs = new address[](0);

        messageRequest = _buildMessageRequest(validatorLibs);

        error = abi.encodeWithSelector(
            IConceroRouter.InvalidValidatorsCount.selector,
            validatorLibs.length,
            s_conceroRouter.getMaxValidatorsCount()
        );

        vm.expectRevert(error);
        s_conceroRouter.getMessageFee(messageRequest);

        vm.expectRevert(error);
        s_conceroRouter.conceroSend(messageRequest);
    }
}
