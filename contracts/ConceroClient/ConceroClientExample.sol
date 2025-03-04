// SPDX-License-Identifier: MIT
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;
import {console} from "hardhat/console.sol";
import {IConceroRouter} from "../interfaces/IConceroRouter.sol";
import {ConceroClient} from "./ConceroClient.sol";
import {ConceroTypes} from "./ConceroTypes.sol";
import {ConceroUtils} from "./ConceroUtils.sol";

contract ConceroClientExample is ConceroClient {
    event MessageReceived(bytes32 messageId, bytes message);

    constructor(
        address conceroRouter,
        uint24 chainSelector
    ) ConceroClient(conceroRouter, chainSelector) {}

    function _conceroReceive(bytes32 messageId, bytes calldata message) internal override {
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
        console.logString("ConceroClientExample: Message sent");
        console.logBytes32(messageId);
    }
}
