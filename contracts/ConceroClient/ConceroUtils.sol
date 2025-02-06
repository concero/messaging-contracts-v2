// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {MessageConstants as MCC} from "../common/libraries/Message.sol";
import {ConceroTypes} from "./ConceroTypes.sol";

library ConceroUtils {
    /// @notice Builds the client message config, and packs it as a uint256
    /// @param clientConfig The client message configuration
    /// @return The encoded message configuration
    function _packClientMessageConfig(
        ConceroTypes.ClientMessageConfig memory clientConfig
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
}
