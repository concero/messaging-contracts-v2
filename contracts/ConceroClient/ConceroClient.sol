// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {InternalMessageConfig, ClientMessage} from "../Common/MessageTypes.sol";
import {IConceroClient} from "../Interfaces/IConceroClient.sol";

error InvalidRouter(address router);

abstract contract ConceroClient is IConceroClient {
    address internal immutable i_conceroRouter;

    constructor(address router) {
        require(router != address(0), InvalidRouter(router));
        i_conceroRouter = router;
    }

    function conceroReceive(bytes32 messageId, ClientMessage calldata message) external {
        require(msg.sender == i_conceroRouter, InvalidRouter(msg.sender));
        _conceroReceive(messageId, message);
    }

    function _conceroReceive(bytes32 messageId, ClientMessage calldata message) internal virtual;

    // Client can use this to optionally build the message config on-chain
    function buildMessageConfig(
        InternalMessageConfig memory config
    ) internal pure returns (uint256) {
        return
            uint256(
                (uint256(config.version) << 248) |
                    (uint256(config.srcChainSelector) << 224) |
                    (uint256(config.dstChainSelector) << 200) |
                    (uint256(config.minSrcConfirmations) << 184) |
                    (uint256(config.minDstConfirmations) << 168) |
                    (uint256(config.additionalRelayers) << 160) |
                    (uint256(config.isCallbackable ? 1 : 0) << 158)
            );
    }

    /* Sending a message to the router */
    //    ClientMessageConfig memory messageConfig = ClientMessageConfig({
    //        dstChainSelector: 1,
    //        minSrcConfirmations: 1,
    //        minDstConfirmations: 1,
    //        additionalRelayers: 0,
    //        feeToken: FeeToken.native,
    //        isCallbackable: false
    //    });
    //
    //    EvmDstChainData memory dstChainData = EvmDstChainData({
    //        receiver: address(0),
    //        gasLimit: 0
    //    });
    //
    //    ClientMessageRequest memory req = ClientMessageRequest({
    //        messageConfig: buildMessageConfig(messageConfig),
    //        dstChainData: dstChainData,
    //        message: bytes("Hello, World!")
    //    });
    //
    //    IConceroRouter(i_conceroRouter).sendMessage{value: msg.value}(req);
}
