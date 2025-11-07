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

    uint24 internal s_srcChainSelector = 3;
    uint24 internal s_dstChainSelector = 8;
    uint64 internal s_srcBlockConfirmations = 9;
    uint32 internal s_gasLimit = 300_00;
    uint256 internal s_nonce = 5777982;

    address internal s_relayerLib = makeAddr("relayerLib");
    address internal s_sender = makeAddr("sender");
    address internal s_receiver = makeAddr("receiver");
    address internal s_feeToken = makeAddr("feeToken");
    address internal s_dstRelayerLibAddr = makeAddr("dstRelayer");

    bytes internal s_dstRelayer = abi.encodePacked(s_dstRelayerLibAddr);
    bytes internal s_dstChainData = MessageCodec.encodeEvmDstChainData(s_receiver, s_gasLimit);
    bytes internal s_relayerConfig = abi.encodePacked("relayerConfig");
    bytes internal s_payload = abi.encodePacked(bytes1(uint8(7)));

    bytes[] internal s_dstValidatorLibs = new bytes[](2);
    bytes[] internal s_validatorConfigs = new bytes[](2);
    bytes[] internal s_validationRpcs = new bytes[](1);
    bytes[] internal s_deliveryRpcs = new bytes[](1);

    address[] internal s_srcValidatorLibs = new address[](2);
    address[] internal s_dstValidatorAddresses = new address[](2);

    function setUp() public {
        s_srcValidatorLibs[0] = makeAddr("srcValidator1");
        s_srcValidatorLibs[1] = makeAddr("srcValidator2");

        s_dstValidatorAddresses[0] = makeAddr("dstValidator1");
        s_dstValidatorAddresses[1] = makeAddr("dstValidator2");

        s_dstValidatorLibs[0] = abi.encodePacked(s_dstValidatorAddresses[0]);
        s_dstValidatorLibs[1] = abi.encodePacked(s_dstValidatorAddresses[1]);

        s_validatorConfigs[0] = abi.encode(keccak256("validatorConfigs1"));
        s_validatorConfigs[1] = abi.encode(keccak256("validatorConfigs2"));

        s_validationRpcs[0] = abi.encodePacked(bytes1(uint8(4)));
        s_deliveryRpcs[0] = abi.encodePacked(bytes1(uint8(5)));
    }

    function test_encode() public {
        vm.pauseGasMetering();

        IConceroRouter.MessageRequest memory messageRequest = IConceroRouter.MessageRequest({
            dstChainSelector: s_dstChainSelector,
            srcBlockConfirmations: s_srcBlockConfirmations,
            feeToken: s_feeToken,
            relayerLib: s_relayerLib,
            validatorLibs: s_srcValidatorLibs,
            validatorConfigs: s_validatorConfigs,
            relayerConfig: s_relayerConfig,
            validationRpcs: s_validationRpcs,
            deliveryRpcs: s_deliveryRpcs,
            dstChainData: s_dstChainData,
            payload: s_payload
        });

        bytes memory messageBytes = messageRequest.toMessageReceiptBytes(
            s_srcChainSelector,
            s_sender,
            s_nonce,
            s_dstRelayer,
            s_dstValidatorLibs
        );

        vm.resumeGasMetering();

        (address sender, uint64 srcBlockConfirmations) = messageBytes.evmSrcChainData();
        (address receiver, uint32 gasLimit) = messageBytes.evmDstChainData();

        vm.pauseGasMetering();

        assertEq(messageBytes.version(), MessageCodec.VERSION);
        assertEq(messageBytes.srcChainSelector(), s_srcChainSelector);
        assertEq(messageBytes.dstChainSelector(), messageRequest.dstChainSelector);
        assertEq(sender, s_sender);
        assertEq(messageBytes.nonce(), s_nonce);
        assertEq(srcBlockConfirmations, s_srcBlockConfirmations);
        assertEq(receiver, s_receiver);
        assertEq(gasLimit, s_gasLimit);
        assertEq(messageBytes.emvDstRelayerLib(), s_dstRelayerLibAddr);
        assertEq(messageRequest.relayerConfig, messageBytes.relayerConfig());
        assertEq(messageBytes.evmDstValidatorLibs(), s_dstValidatorAddresses);
        assertEq(messageBytes.validatorConfigs(), s_validatorConfigs);
        assertEq(messageBytes.validationRpcs(), s_validationRpcs);
        assertEq(messageBytes.deliveryRpcs(), s_deliveryRpcs);
        assertEq(messageBytes.payload(), s_payload);

        vm.resumeGasMetering();
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_encode_RevertsIfInvalidGasLimit() public {
        vm.expectRevert(IConceroRouter.InvalidGasLimit.selector);
        MessageCodec.encodeEvmDstChainData(s_receiver, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_encode_RevertsIfInvalidReceiver() public {
        vm.expectRevert(IRelayer.InvalidReceiver.selector);
        MessageCodec.encodeEvmDstChainData(address(0), s_gasLimit);
    }
}
