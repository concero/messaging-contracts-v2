//SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonTypes} from "../CommonTypes.sol";
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

    function _decodeVerifierResult(
        bytes memory result
    ) internal pure returns (CommonTypes.ResultConfig memory resultConfig, bytes memory payload) {
        return abi.decode(result, (CommonTypes.ResultConfig, bytes));
    }
}
