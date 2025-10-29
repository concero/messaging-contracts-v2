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
import {MessageCodec} from "contracts/common/libraries/MessageCodec.sol";

contract MessageCodecTest is Test {
    using MessageCodec for IConceroRouter.MessageRequest;
    using MessageCodec for bytes;

    uint8 internal constant VERSION = 1;

    uint24 internal s_srcChainSelector = 3;
    uint24 internal s_dstChainSelector = 8;
    uint64 internal s_srcBlockConfirmations = 9;
    uint32 internal s_gasLimit = 300_00;

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
            s_dstRelayer,
            s_dstValidatorLibs
        );

        vm.resumeGasMetering();

        (address sender, uint64 srcBlockConfirmations) = messageBytes.evmSrcChainData();
        (address receiver, uint32 gasLimit) = messageBytes.evmDstChainData();
        address[] memory dstValidatorLibs = messageBytes.evmDstValidatorLibs();
        bytes[] memory validatorConfigs = messageBytes.validatorConfigs();
        bytes[] memory validationRpcs = messageBytes.validationRpcs();

        vm.pauseGasMetering();

        assertEq(messageBytes.version(), VERSION);
        assertEq(messageBytes.srcChainSelector(), s_srcChainSelector);
        assertEq(messageBytes.dstChainSelector(), messageRequest.dstChainSelector);
        assertEq(sender, s_sender);
        assertEq(srcBlockConfirmations, s_srcBlockConfirmations);
        assertEq(receiver, s_receiver);
        assertEq(gasLimit, s_gasLimit);
        assertEq(messageBytes.emvDstRelayerLib(), s_dstRelayerLibAddr);
        assertEq(messageRequest.relayerConfig, messageBytes.relayerConfig());
        assertEq(dstValidatorLibs, s_dstValidatorAddresses);
        assertEq(validatorConfigs, s_validatorConfigs);
        assertEq(validationRpcs, s_validationRpcs);

        vm.resumeGasMetering();
    }
}
