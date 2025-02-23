//SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;
import {console} from "forge-std/src/console.sol";
import {CommonTypes} from "../CommonTypes.sol";
import {MessageConfigBitOffsets, ReportConfigBitOffsets, ReportByteSizes} from "../CommonConstants.sol";
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
        ) = abi.decode(
            report,
            (bytes32[], bytes[], bytes[], bytes[], bytes[])
        );

        return decodedReport;
    }

    function _decodeCLFReportConfig(
        uint256 reportConfig
    ) internal pure returns (uint8 reportType, uint8 version, address requester) {
        uint256 BYTE_MASK = 0xFF;

        reportType = uint8((reportConfig >> ReportConfigBitOffsets.OFFSET_REPORT_TYPE) & BYTE_MASK);
        version = uint8((reportConfig >> ReportConfigBitOffsets.OFFSET_VERSION) & BYTE_MASK);
        requester = address(uint160(reportConfig));
    }

    function decodeInternalMessageConfig(
        uint256 config
    ) private pure returns (RouterTypes.InternalMessageConfig memory) {
        return
            RouterTypes.InternalMessageConfig({
                version: uint8(config >> MessageConfigBitOffsets.OFFSET_VERSION),
                srcChainSelector: uint24(config >> MessageConfigBitOffsets.OFFSET_SRC_CHAIN),
                dstChainSelector: uint24(config >> MessageConfigBitOffsets.OFFSET_DST_CHAIN),
                minSrcConfirmations: uint16(config >> MessageConfigBitOffsets.OFFSET_MIN_SRC_CONF),
                minDstConfirmations: uint16(config >> MessageConfigBitOffsets.OFFSET_MIN_DST_CONF),
                relayerConfig: uint8(config >> MessageConfigBitOffsets.OFFSET_RELAYER_CONF),
                isCallbackable: (config & (1 << MessageConfigBitOffsets.OFFSET_CALLBACKABLE)) != 0
            });
    }

    function _decodeCLFMessageReportResponse(
        bytes memory response
    ) internal pure returns (CommonTypes.MessageReportResult memory) {
        uint256 offset = 0;
        uint256 reportConfig;
        bytes32 internalMessageConfig;
        bytes32 messageId;
        bytes32 messageHashSum;
        uint32 dstChainDataLength;
        bytes memory dstChainData;
        uint16 allowedOperatorsLength;
        bytes32[] memory rawAllowedOperators;
        bytes[] memory allowedOperators;

        uint8 size_report_config = ReportByteSizes.SIZE_WORD;
        uint8 size_internal_message_config = ReportByteSizes.SIZE_INTERNAL_MESSAGE_CONFIG;
        uint8 size_message_id = ReportByteSizes.SIZE_MESSAGE_ID;
        uint8 size_message_hash_sum = ReportByteSizes.SIZE_MESSAGE_HASH_SUM;
        uint8 size_dst_chain_data_length = ReportByteSizes.SIZE_DST_CHAIN_DATA_LENGTH;
        uint8 size_allowed_operators_length = ReportByteSizes.SIZE_ALLOWED_OPERATORS_LENGTH;
        uint8 size_allowed_operator = ReportByteSizes.SIZE_ALLOWED_OPERATOR;

        assembly {
            // Read reportConfig (32 bytes for uint256)
            reportConfig := mload(add(response, add(offset, 32)))
            offset := add(offset, size_report_config)

            // Read internalMessageConfig (32 bytes)
            internalMessageConfig := mload(add(response, add(offset, 32)))
            offset := add(offset, size_internal_message_config)

            // Read messageId (32 bytes)
            messageId := mload(add(response, add(offset, 32)))
            offset := add(offset, size_message_id)

            // Read messageHashSum (32 bytes)
            messageHashSum := mload(add(response, add(offset, 32)))
            offset := add(offset, size_message_hash_sum)

            // Read dstChainData length (4 bytes as uint32)
            dstChainDataLength := shr(224, mload(add(response, add(offset, 32))))
            offset := add(offset, size_dst_chain_data_length)
        }

        dstChainData = new bytes(dstChainDataLength);
        for (uint256 i = 0; i < dstChainDataLength; i++) {
            dstChainData[i] = response[offset + i];
        }
        offset += dstChainDataLength;

        assembly {
            allowedOperatorsLength := shr(240, mload(add(response, add(0x20, offset))))
            offset := add(offset, size_allowed_operators_length)
        }

        rawAllowedOperators = new bytes32[](allowedOperatorsLength);
        for (uint16 i = 0; i < allowedOperatorsLength; i++) {
            assembly {
                let operatorValue := mload(add(response, add(offset, 32)))
                mstore(add(add(rawAllowedOperators, 0x20), mul(i, 0x20)), operatorValue)
            }
            offset += size_allowed_operator;
        }

        allowedOperators = new bytes[](allowedOperatorsLength);
        for (uint16 i = 0; i < allowedOperatorsLength; i++) {
            bytes memory operatorBytes = new bytes(32);
            assembly {
                mstore(
                    add(operatorBytes, 32),
                    mload(add(add(rawAllowedOperators, 0x20), mul(i, 0x20)))
                )
            }
            allowedOperators[i] = operatorBytes;
        }

        return
            CommonTypes.MessageReportResult({
                reportConfig: reportConfig,
                internalMessageConfig: uint256(internalMessageConfig),
                messageId: messageId,
                messageHashSum: messageHashSum,
                dstChainData: dstChainData,
                allowedOperators: allowedOperators
            });
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
        ) = abi.decode(response, (
            uint256,
            CommonTypes.ChainType[],
            VerifierTypes.OperatorRegistrationAction[],
            bytes[]
        ));

        return result;
    }
}
