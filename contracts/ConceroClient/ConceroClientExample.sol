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

    constructor(address router, uint24 chainSelector) ConceroClient(router, chainSelector) {}

    function _conceroReceive(bytes32 messageId, bytes calldata message) internal override {
        emit MessageReceived(messageId, message);
    }

    function sendConceroMessage() external payable returns (bytes32 messageId) {
        // Build a message config on-chain (optional), or provide packedConfig directly
        ConceroTypes.ClientMessageConfig memory config = ConceroTypes.ClientMessageConfig({
            dstChainSelector: 1,
            minSrcConfirmations: 2,
            minDstConfirmations: 2,
            relayerConfig: 1,
            isCallbackable: true,
            feeToken: ConceroTypes.FeeToken.native
        });

        uint256 packedConfig = ConceroUtils._packClientMessageConfig(config);

        // Build the destination chain data
        bytes memory dstChainData = abi.encode(
            ConceroTypes.EvmDstChainData({receiver: address(0), gasLimit: 0})
        );

        // Send a message to the router
        messageId = IConceroRouter(i_conceroRouter).conceroSend{value: msg.value}(
            packedConfig,
            dstChainData,
            "Hello, World!"
        );
    }
}
