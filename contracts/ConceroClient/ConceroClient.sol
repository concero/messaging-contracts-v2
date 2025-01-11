// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {InternalMessageConfig, ClientMessage, ClientMessageConfig} from "../Common/MessageTypes.sol";
import {IConceroClient} from "../Interfaces/IConceroClient.sol";
import {MessageConfigConstants as MCC} from "../Libraries/MessageLib.sol";

error InvalidRouter(address router);

abstract contract ConceroClient is IConceroClient {
    uint8 internal constant VERSION = 1;
    address internal immutable i_conceroRouter;
    uint24 internal immutable i_chainSelector;

    constructor(address router, uint24 chainSelector) {
        require(router != address(0), InvalidRouter(router));
        i_conceroRouter = router;
        i_chainSelector = chainSelector;
    }

    function conceroReceive(bytes32 messageId, ClientMessage calldata message) external {
        require(msg.sender == i_conceroRouter, InvalidRouter(msg.sender));
        _conceroReceive(messageId, message);
    }

    function _conceroReceive(bytes32 messageId, ClientMessage calldata message) internal virtual;

    // Client can use this to optionally build the message config on-chain
    function buildClientMessageConfig(
        ClientMessageConfig memory clientConfig
    ) internal pure returns (uint256) {
        uint256 config;

        config |= uint256(clientConfig.dstChainSelector) << MCC.OFFSET_DST_CHAIN;
        config |= uint256(clientConfig.minSrcConfirmations) << MCC.OFFSET_MIN_SRC_CONF;
        config |= uint256(clientConfig.minDstConfirmations) << MCC.OFFSET_MIN_DST_CONF;
        config |= uint256(clientConfig.relayerConfig) << MCC.OFFSET_RELAYER_CONF;
        config |= uint256(clientConfig.isCallbackable ? 1 : 0) << MCC.OFFSET_CALLBACKABLE;
        config |= uint256(clientConfig.feeToken) << MCC.OFFSET_FEE_TOKEN;

        return config;
    }
    /* Sending a message to the router */

    //    EvmDstChainData memory dstChainData = EvmDstChainData({
    //        receiver: address(0),
    //        gasLimit: 0
    //    });
    //
    //    ClientMessageRequest memory req = ClientMessageRequest({
    //        messageConfig: buildClientMessageConfig(messageConfig),
    //        dstChainData: dstChainData,
    //        message: bytes("Hello, World!")
    //    });
    //
    //    IConceroRouter(i_conceroRouter).sendMessage{value: msg.value}(req);
}
