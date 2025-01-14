//SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;
import {MessageReportResult, ReportType} from "../Interfaces/IConceroVerifier.sol";
error IncorrectNumberOfSignatures();
error UnauthorizedSigner(address signer);
error DuplicateSignatureDetected(address signer);

library SignerLib {
    uint8 internal constant SIZE_VERSION = 1;
    uint8 internal constant SIZE_REPORT_TYPE = 1;
    uint8 internal constant SIZE_OPERATOR = 32;
    uint8 internal constant SIZE_INTERNAL_MESSAGE_CONFIG = 32;
    uint8 internal constant SIZE_MESSAGE_ID = 32;
    uint8 internal constant SIZE_MESSAGE_HASH_SUM = 32;
    uint8 internal constant SIZE_DST_CHAIN_DATA_LENGTH = 4;
    uint8 internal constant SIZE_OPERATOR_COUNT = 2;
    uint8 internal constant SIZE_OPERATOR_ENTRY = 32;

    /* CLF DON SIGNERS */
    address internal constant CLF_DON_SIGNER_0 = 0xCCCcAC597660Eebf71b424415f874ee4c6b13D22;
    address internal constant CLF_DON_SIGNER_1 = 0xCCCcAC597660Eebf71b424415f874ee4c6b13D22;
    address internal constant CLF_DON_SIGNER_2 = 0xCCCcAC597660Eebf71b424415f874ee4c6b13D22;
    address internal constant CLF_DON_SIGNER_3 = 0xCCCcAC597660Eebf71b424415f874ee4c6b13D22;

    struct ClfDonReportSubmission {
        bytes32[3] context;
        bytes report;
        bytes32[] rs;
        bytes32[] ss;
        bytes rawVs;
    }

    function _decodeCLFReportResponse(
        bytes memory response
    ) internal pure returns (MessageReportResult memory) {
        uint256 offset = 0;
        uint8 version;
        uint8 reportType;
        address operator;
        bytes32 internalMessageConfig;
        bytes32 messageId;
        bytes32 messageHashSum;
        uint32 dstChainDataLength;
        bytes memory dstChainData;
        uint16 allowedOperatorsCount;
        bytes32[] memory rawAllowedOperators;
        bytes[] memory allowedOperators;

        assembly {
            // Read version (1 byte) and reportType (1 byte)
            version := byte(0, mload(add(response, offset)))
            reportType := byte(1, mload(add(response, offset)))
            offset := add(offset, SIZE_VERSION)
            offset := add(offset, SIZE_REPORT_TYPE)

            // Read operator (20 bytes padded to 32 bytes)
            operator := shr(96, mload(add(response, offset)))
            offset := add(offset, SIZE_OPERATOR)

            // Read internalMessageConfig (32 bytes)
            internalMessageConfig := mload(add(response, offset))
            offset := add(offset, SIZE_INTERNAL_MESSAGE_CONFIG)

            // Read messageId (32 bytes)
            messageId := mload(add(response, offset))
            offset := add(offset, SIZE_MESSAGE_ID)

            // Read messageHashSum (32 bytes)
            messageHashSum := mload(add(response, offset))
            offset := add(offset, SIZE_MESSAGE_HASH_SUM)

            // Read dstChainData length (4 bytes as uint32)
            dstChainDataLength := shr(224, mload(add(response, offset)))
            offset := add(offset, SIZE_DST_CHAIN_DATA_LENGTH)
        }

        // Read dstChainData (variable length based on dstChainDataLength)
        dstChainData = new bytes(dstChainDataLength);
        for (uint256 i = 0; i < dstChainDataLength; i++) {
            dstChainData[i] = response[offset + i];
        }
        offset += dstChainDataLength;

        assembly {
            // Read allowedOperators count (2 bytes as uint16)
            allowedOperatorsCount := shr(240, mload(add(response, offset)))
            offset := add(offset, SIZE_OPERATOR_COUNT)
        }

        // Initialize and read allowedOperators (32 bytes each)
        rawAllowedOperators = new bytes32[](allowedOperatorsCount);
        for (uint16 i = 0; i < allowedOperatorsCount; i++) {
            assembly {
                let operatorValue := mload(add(response, offset))
                mstore(add(add(rawAllowedOperators, 0x20), mul(i, 0x20)), operatorValue)
            }
            offset += SIZE_OPERATOR_ENTRY;
        }

        allowedOperators = new bytes[](allowedOperatorsCount);
        for (uint16 i = 0; i < allowedOperatorsCount; i++) {
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
            MessageReportResult({
                version: version,
                reportType: ReportType(reportType),
                operator: operator,
                internalMessageConfig: internalMessageConfig,
                messageId: messageId,
                messageHashSum: messageHashSum,
                dstChainData: dstChainData,
                allowedOperators: allowedOperators
            });
    }

    function _isAuthorizedClfDonSigner(address clfDonSigner) internal view returns (bool) {
        if (clfDonSigner == address(0)) {
            return false;
        }

        return (clfDonSigner == CLF_DON_SIGNER_0 ||
            clfDonSigner == CLF_DON_SIGNER_1 ||
            clfDonSigner == CLF_DON_SIGNER_2 ||
            clfDonSigner == CLF_DON_SIGNER_3);
    }

    /**
     * @notice Computes the hash of the report and report context.
     * @param reportContext The context of the report.
     * @param report The serialized report data.
     * @return The computed hash of the report.
     */
    function _computeCLFReportHash(
        bytes32[3] calldata reportContext,
        bytes calldata report
    ) internal pure returns (bytes32) {
        bytes32 reportHash = keccak256(report);
        bytes memory messageToHash = abi.encodePacked(reportHash, reportContext);
        return keccak256(messageToHash);
    }

    /**
     * @notice Verifies the signatures of the report.
     * @param reportSubmission The report submission data.
     */
    function _verifyClfReportSignatures(
        ClfDonReportSubmission calldata reportSubmission
    ) internal view {
        bytes32 clfReportHash = _computeCLFReportHash(
            reportSubmission.context,
            reportSubmission.report
        );
        bytes32[] memory rs = reportSubmission.rs;
        bytes32[] memory ss = reportSubmission.ss;
        bytes memory rawVs = reportSubmission.rawVs;

        uint256 expectedNumSignatures = 3;

        require(
            rs.length == ss.length && rs.length == expectedNumSignatures,
            IncorrectNumberOfSignatures()
        );

        address[] memory signers = new address[](rs.length);

        for (uint256 i; i < rs.length; i++) {
            uint8 v = uint8(rawVs[i]) + 27;
            bytes32 r = rs[i];
            bytes32 s = ss[i];

            address signer = ecrecover(clfReportHash, v, r, s);
            require(_isAuthorizedClfDonSigner(signer), UnauthorizedSigner(signer));

            for (uint256 j = 0; j < i; j++) {
                require(signers[j] != signer, DuplicateSignatureDetected(signer));
            }

            signers[i] = signer;
        }
    }
}
