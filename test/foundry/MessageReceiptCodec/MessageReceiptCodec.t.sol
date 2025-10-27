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
import {MessageReceiptCodec} from "contracts/common/libraries/MessageReceiptCodec.sol";

contract MessageReceiptCodecTest is Test {
    using MessageReceiptCodec for IConceroRouter.MessageRequest;

    function test_encode() public {
        IConceroRouter.MessageRequest memory messageReceipt = IConceroRouter.MessageRequest({
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

        console.logBytes(
            messageReceipt.toMessageReceiptBytes(
                0xd12caf,
                makeAddr("sender"),
                new bytes(10),
                dstValidatorLibs
            )
        );
    }
}
