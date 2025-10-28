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

    function test_encode() public {
        vm.pauseGasMetering();

        address[] memory validatorLibs = new address[](2);
        validatorLibs[0] = makeAddr("validator4");
        validatorLibs[1] = makeAddr("validator5");

        bytes[] memory dstValidatorLibs = new bytes[](2);
        dstValidatorLibs[0] = abi.encodePacked(bytes1(uint8(1)));
        dstValidatorLibs[1] = abi.encodePacked(bytes1(uint8(1)));

        bytes[] memory validatorConfigs = new bytes[](2);
        validatorConfigs[0] = abi.encodePacked(bytes1(uint8(2)));
        validatorConfigs[0] = abi.encodePacked(bytes1(uint8(2)));

        bytes memory dstRelayerLib = abi.encodePacked(
            bytes32(uint256(uint160(makeAddr("relayer"))))
        );
        bytes memory relayerConfig = abi.encodePacked(bytes1(uint8(3)));

        bytes[] memory validationRpcs = new bytes[](1);
        validationRpcs[0] = abi.encodePacked(bytes1(uint8(4)));

        bytes[] memory deliveryRpcs = new bytes[](1);
        deliveryRpcs[0] = abi.encodePacked(bytes1(uint8(5)));

        bytes memory dstChainData = abi.encodePacked(bytes1(uint8(6)));

        bytes memory payload = abi.encodePacked(bytes1(uint8(7)));

        IConceroRouter.MessageRequest memory messageRequest = IConceroRouter.MessageRequest({
            dstChainSelector: 8,
            srcBlockConfirmations: 9,
            feeToken: makeAddr("feeToken"),
            relayerLib: makeAddr("relayerLib"),
            validatorLibs: validatorLibs,
            validatorConfigs: validatorConfigs,
            relayerConfig: relayerConfig,
            validationRpcs: validationRpcs,
            deliveryRpcs: deliveryRpcs,
            dstChainData: dstChainData,
            payload: payload
        });

        vm.resumeGasMetering();
        bytes memory messageBytes = messageRequest.toMessageReceiptBytes(
            11,
            makeAddr("sender"),
            dstRelayerLib,
            dstValidatorLibs
        );

        vm.pauseGasMetering();

        console.logBytes(messageBytes);

        vm.resumeGasMetering();
    }
}
