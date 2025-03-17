// SPDX-License-Identifier: MIT
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IConceroRouter} from "../interfaces/IConceroRouter.sol";
import {ConceroClient} from "./ConceroClient.sol";
import {ConceroTypes} from "./ConceroTypes.sol";
import {ConceroUtils} from "./ConceroUtils.sol";

contract ConceroClientExample is ConceroClient {
    event MessageReceived(bytes32 messageId, bytes message);

    constructor(address conceroRouter) ConceroClient(conceroRouter) {}

    function _conceroReceive(
        bytes32 messageId,
        uint24 srcChainSelector,
        bytes calldata sender,
        bytes calldata message
    ) internal override {
        emit MessageReceived(messageId, message);
    }

    function sendConceroMessage(address receiver) external payable returns (bytes32 messageId) {
        // Build a message config on-chain (optional), or provide packedConfig directly
        ConceroTypes.ClientMessageConfig memory config = ConceroTypes.ClientMessageConfig({
            dstChainSelector: 1,
            minSrcConfirmations: 1,
            minDstConfirmations: 1,
            relayerConfig: 0,
            isCallbackable: false,
            feeToken: ConceroTypes.FeeToken.native
        });

        bytes32 packedConfig = ConceroUtils._packClientMessageConfig(config);

        // Build the destination chain data
        bytes memory dstChainData = abi.encode(
            ConceroTypes.EvmDstChainData({receiver: receiver, gasLimit: 100_000})
        );

        // Send a message to the router
        messageId = IConceroRouter(i_conceroRouter).conceroSend{value: msg.value}(
            packedConfig,
            dstChainData,
            "Hello, World!"
        );
        //        console.logString("ConceroClientExample: Message sent");
        //        console.logBytes32(messageId);
    }

    function sendConceroMessage(
        uint24 dstChainSelector,
        uint8 minSrcConfirmations,
        uint8 minDstConfirmations,
        uint8 relayerConfig,
        bool isCallbackable,
        ConceroTypes.FeeToken feeToken,
        address receiver,
        uint256 gasLimit,
        bytes memory messageContent
    ) external payable returns (bytes32 messageId) {
        // Build a message config from the provided parameters
        ConceroTypes.ClientMessageConfig memory config = ConceroTypes.ClientMessageConfig({
            dstChainSelector: dstChainSelector,
            minSrcConfirmations: minSrcConfirmations,
            minDstConfirmations: minDstConfirmations,
            relayerConfig: relayerConfig,
            isCallbackable: isCallbackable,
            feeToken: feeToken
        });

        bytes32 packedConfig = ConceroUtils._packClientMessageConfig(config);

        // Build the destination chain data with provided receiver and gas limit
        bytes memory dstChainData = abi.encode(
            ConceroTypes.EvmDstChainData({receiver: receiver, gasLimit: gasLimit})
        );

        // Send a message to the router with the provided message content
        messageId = IConceroRouter(i_conceroRouter).conceroSend{value: msg.value}(
            packedConfig,
            dstChainData,
            messageContent
        );
    }
}
