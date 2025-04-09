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
