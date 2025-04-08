// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Types} from "../../ConceroRouter/libraries/Types.sol";
import {CommonTypes} from "../../common/CommonTypes.sol";
import {CommonConstants, MessageConfigBitOffsets as offsets, ReportByteSizes} from "../../common/CommonConstants.sol";

library Message {
    enum MessageConfigErrorType {
        InvalidMinSrcConfirmations, // 0
        InvalidMinDstConfirmations, // 1
        InvalidAdditionalRelayers, // 2
        InvalidFeeToken, // 3
        InvalidConfigVersion, // 4
        InvalidRelayerConfig, // 5
        InvalidSrcChainSelector, // 6
        InvalidDstChainSelector, // 7
        InvalidOperatorLength // 8
    }

    error MessageTooLarge();
    error InvalidClientMessageConfig(MessageConfigErrorType error);
    error InvalidDstChainData();
    error InvalidSrcChainData();
    error InvalidInternalMessageConfig(MessageConfigErrorType error);

    /* VALIDATION FUNCTIONS */

    function validateInternalMessage(
        bytes32 internalMessageConfig,
        bytes memory srcChainData,
        bytes memory dstChainData
    ) internal view {
        validateInternalMessageConfig(internalMessageConfig);
        require(srcChainData.length > 0, InvalidSrcChainData());
        require(dstChainData.length > 0, InvalidDstChainData());
    }

    //to be moved to conceroRouter as a module

    // to be moved to ConceroVerifier as a module
    function validateInternalMessageConfig(bytes32 config) private view {
        uint256 configValue = uint256(config);

        uint8 version = uint8(configValue >> offsets.OFFSET_VERSION);
        uint8 relayerConfig = uint8(configValue >> offsets.OFFSET_RELAYER_CONF);
        uint16 minSrcConfirmations = uint16(configValue >> offsets.OFFSET_MIN_SRC_CONF);
        uint16 minDstConfirmations = uint16(configValue >> offsets.OFFSET_MIN_DST_CONF);
        uint24 srcChainSelector = uint24(configValue >> offsets.OFFSET_SRC_CHAIN);
        uint24 dstChainSelector = uint24(configValue >> offsets.OFFSET_DST_CHAIN);

        require(
            version >= 1 && version < 2,
            InvalidInternalMessageConfig(MessageConfigErrorType.InvalidConfigVersion)
        );
        require(
            minSrcConfirmations > 0,
            InvalidInternalMessageConfig(MessageConfigErrorType.InvalidMinSrcConfirmations)
        );
        require(
            minDstConfirmations > 0,
            InvalidInternalMessageConfig(MessageConfigErrorType.InvalidMinDstConfirmations)
        );
        //        require(
        //            SupportedChains.isChainSupported(srcChainSelector),
        //            InvalidInternalMessageConfig(MessageConfigErrorType.InvalidSrcChainSelector)
        //        );
        //        require(
        //            SupportedChains.isChainSupported(dstChainSelector),
        //            InvalidInternalMessageConfig(MessageConfigErrorType.InvalidDstChainSelector)
        //        );
    }
}
