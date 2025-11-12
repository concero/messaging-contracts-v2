// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/console.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {IRelayer} from "contracts/interfaces/IRelayer.sol";
import {MessageCodec} from "contracts/common/libraries/MessageCodec.sol";

contract MessageCodecTest is Test {
    using MessageCodec for IConceroRouter.MessageRequest;
    using MessageCodec for bytes;

    /// forge-config: default.allow_internal_expect_revert = true
    function test_encode_RevertsIfInvalidGasLimit() public {
        vm.expectRevert(IConceroRouter.InvalidGasLimit.selector);
        MessageCodec.encodeEvmDstChainData(makeAddr("receiver"), 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_encode_RevertsIfInvalidReceiver() public {
        vm.expectRevert(IRelayer.InvalidReceiver.selector);
        MessageCodec.encodeEvmDstChainData(address(0), 100_000);
    }

    function testFuzz_encodeDecode(
        IConceroRouter.MessageRequest memory messageRequest,
        uint24 srcChainSelector,
        address sender,
        uint256 nonce,
        address receiver,
        uint32 dstChainGasLimit
    ) public view {
        _assumeMessageRequest(messageRequest, dstChainGasLimit, receiver);

        messageRequest.dstChainData = MessageCodec.encodeEvmDstChainData(
            receiver,
            dstChainGasLimit
        );

        bytes memory messageBytes = messageRequest.toMessageReceiptBytes(
            srcChainSelector,
            sender,
            nonce
        );

        (address decodedSender, uint64 srcBlockConfirmations) = messageBytes.evmSrcChainData();
        (address decodedReceiver, uint32 decodedGasLimit) = messageBytes.evmDstChainData();

        assertEq(messageBytes.version(), MessageCodec.VERSION, "version");
        assertEq(messageBytes.srcChainSelector(), srcChainSelector);
        assertEq(messageBytes.dstChainSelector(), messageRequest.dstChainSelector);
        assertEq(decodedSender, sender);
        assertEq(messageBytes.nonce(), nonce);
        assertEq(
            srcBlockConfirmations,
            messageRequest.srcBlockConfirmations,
            "srcBlockConfirmations"
        );
        assertEq(decodedReceiver, receiver);
        assertEq(decodedGasLimit, dstChainGasLimit);
        assertEq(messageRequest.relayerConfig, messageBytes.relayerConfig());
        assertEq(messageBytes.validatorConfigs(), messageRequest.validatorConfigs);
        assertEq(messageBytes.payload(), messageRequest.payload);
    }

    function _assumeMessageRequest(
        IConceroRouter.MessageRequest memory messageRequest,
        uint32 dstChainGasLimit,
        address receiver
    ) internal pure {
        vm.assume(messageRequest.validatorLibs.length < type(uint24).max);
        vm.assume(messageRequest.validatorConfigs.length < type(uint24).max);
        vm.assume(messageRequest.relayerConfig.length < type(uint24).max);
        vm.assume(messageRequest.payload.length < type(uint24).max);
        vm.assume(dstChainGasLimit > 0);
        vm.assume(dstChainGasLimit > 0);
        vm.assume(receiver != address(0));
    }
}
