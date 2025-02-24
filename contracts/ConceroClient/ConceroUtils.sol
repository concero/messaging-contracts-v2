// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;
import {console} from "forge-std/src/console.sol";
import {MessageConfigBitOffsets as offsets, BitMasks as masks} from "../common/CommonConstants.sol";
import {ConceroTypes} from "./ConceroTypes.sol";

library ConceroUtils {
    /// @notice Builds the client message config, and packs it as a uint256
    /// @param clientConfig The client message configuration
    /// @return The encoded message configuration
        function _packClientMessageConfig(
            ConceroTypes.ClientMessageConfig memory clientConfig
        ) internal pure returns (bytes32) {
            uint256 config;

            config |= (uint256(uint24(clientConfig.dstChainSelector)) & masks.MASK_24) <<
                offsets.OFFSET_DST_CHAIN;

            config |= (uint256(uint16(clientConfig.minSrcConfirmations)) & masks.MASK_16) <<
                offsets.OFFSET_MIN_SRC_CONF;

            config |= (uint256(uint16(clientConfig.minDstConfirmations)) & masks.MASK_16) <<
                offsets.OFFSET_MIN_DST_CONF;

            config |= (uint256(uint8(clientConfig.relayerConfig)) & masks.MASK_8) <<
                offsets.OFFSET_RELAYER_CONF;

            config |= (uint256(clientConfig.isCallbackable ? 1 : 0) & masks.MASK_1) <<
                offsets.OFFSET_CALLBACKABLE;

            config |= (uint256(uint8(clientConfig.feeToken)) & masks.MASK_8) <<
                offsets.OFFSET_FEE_TOKEN;

            return bytes32(config);
        }
    }
