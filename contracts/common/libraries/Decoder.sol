//SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;
import {console} from "forge-std/src/console.sol";
import {CommonTypes} from "../CommonTypes.sol";
import {BitMasks, MessageConfigBitOffsets as offsets, ReportConfigBitOffsets, ReportByteSizes} from "../CommonConstants.sol";
import {ReportByteSizes} from "contracts/common/CommonConstants.sol";

import {Types as RouterTypes} from "../../ConceroRouter/libraries/Types.sol";
import {Types as VerifierTypes} from "../../ConceroVerifier/libraries/Types.sol";

library Decoder {
    /**
     * @notice Decodes the raw CLF report into its constituent parts
     * @param report The raw report to decode
     * @return decodedReport The decoded report components
     */
    function _decodeCLFReport(
        bytes calldata report
    ) internal pure returns (RouterTypes.ClfReport memory decodedReport) {
        (
            decodedReport.requestIds,
            decodedReport.results,
            decodedReport.errors,
            decodedReport.onchainMetadata,
            decodedReport.offchainMetadata
        ) = abi.decode(report, (bytes32[], bytes[], bytes[], bytes[], bytes[]));

        return decodedReport;
    }

    function _decodeCLFReportConfig(
        bytes32 reportConfig
    ) internal pure returns (uint8 reportType, uint8 version, address requester) {
        reportType = uint8(
            uint256(reportConfig >> ReportConfigBitOffsets.OFFSET_REPORT_TYPE) & BitMasks.MASK_8
        );
        version = uint8(
            uint256(reportConfig >> ReportConfigBitOffsets.OFFSET_VERSION) & BitMasks.MASK_8
        );
        requester = address(uint160(uint256(reportConfig)));
    }

    function decodeInternalMessageConfig(
        bytes32 config
    ) internal pure returns (RouterTypes.InternalMessageConfig memory) {
        uint256 configUint = uint256(config);

        return
            RouterTypes.InternalMessageConfig({
                version: uint8((configUint >> offsets.OFFSET_VERSION) & BitMasks.MASK_8),
                srcChainSelector: uint24(
                    (configUint >> offsets.OFFSET_SRC_CHAIN) & BitMasks.MASK_24
                ),
                dstChainSelector: uint24(
                    (configUint >> offsets.OFFSET_DST_CHAIN) & BitMasks.MASK_24
                ),
                minSrcConfirmations: uint16(
                    (configUint >> offsets.OFFSET_MIN_SRC_CONF) & BitMasks.MASK_16
                ),
                minDstConfirmations: uint16(
                    (configUint >> offsets.OFFSET_MIN_DST_CONF) & BitMasks.MASK_16
                ),
                relayerConfig: uint8((configUint >> offsets.OFFSET_RELAYER_CONF) & BitMasks.MASK_8),
                isCallbackable: (configUint & (BitMasks.MASK_1 << offsets.OFFSET_CALLBACKABLE)) != 0
            });
    }

    function _decodeCLFMessageReportResponse(
        bytes memory response
    ) internal pure returns (CommonTypes.MessageReportResult memory) {
        CommonTypes.MessageReportResult memory result;
        (
            result.reportConfig,
            result.internalMessageConfig,
            result.messageId,
            result.messageHashSum,
            result.sender,
            result.dstChainData,
            result.allowedOperators
        ) = abi.decode(response, (bytes32, bytes32, bytes32, bytes32, bytes, bytes, bytes[]));

        return result;
    }

    function _decodeCLFOperatorRegistrationReport(
        bytes memory response
    ) internal pure returns (VerifierTypes.OperatorRegistrationResult memory) {
        VerifierTypes.OperatorRegistrationResult memory result;

        (
            result.reportConfig,
            result.operatorChains,
            result.operatorActions,
            result.operatorAddresses
        ) = abi.decode(
            response,
            (bytes32, CommonTypes.ChainType[], VerifierTypes.OperatorRegistrationAction[], bytes[])
        );

        return result;
    }
}
