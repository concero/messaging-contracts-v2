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
    using MessageReceiptCodec for IConceroRouter.MessageReceipt;

    function test_encode() public {
        IConceroRouter.MessageReceipt memory messageReceipt = IConceroRouter.MessageReceipt({
            srcChainSelector: 1,
            dstChainSelector: 2,
            srcChainData: new bytes(3),
            dstChainData: new bytes(4),
            dstRelayerLib: new bytes(5),
            dstValidatorLibs: new bytes[](6),
            validatorConfigs: new bytes[](6),
            relayerConfig: new bytes(1),
            validationRpcs: new bytes[](2),
            deliveryRpcs: new bytes[](4),
            payload: new bytes(3)
        });

        console.logBytes(messageReceipt.toBytes());
    }
}
