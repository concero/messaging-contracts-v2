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
        IConceroRouter.MessageRequest memory messageRequest = IConceroRouter.MessageRequest({
            dstChainSelector: 0xefacbd,
            srcBlockConfirmations: 590,
            feeToken: makeAddr("feeToken"),
            relayerLib: makeAddr("relayerLib"),
            validatorLibs: new address[](2),
            validatorConfigs: new bytes[](6),
            relayerConfig: new bytes(1),
            validationRpcs: new bytes[](2),
            deliveryRpcs: new bytes[](4),
            dstChainData: new bytes(4),
            payload: new bytes(3)
        });

        bytes[] memory dstValidatorLibs = new bytes[](10);

        vm.resumeGasMetering();
        bytes memory messageBytes = messageRequest.toMessageReceiptBytes1(
            0xd12caf,
            makeAddr("sender"),
            new bytes(10),
            dstValidatorLibs
        );

        vm.pauseGasMetering();

        console.logBytes(messageBytes);

        vm.resumeGasMetering();
    }
}
