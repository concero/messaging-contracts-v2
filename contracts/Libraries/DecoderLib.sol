//SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;
import {MessageReportResult, CLFReportType} from "../Interfaces/IConceroVerifier.sol";

library DecoderLib {
    uint8 internal constant SIZE_VERSION = 1;
    uint8 internal constant SIZE_REPORT_TYPE = 1;
    uint8 internal constant SIZE_OPERATOR = 32;
    uint8 internal constant SIZE_INTERNAL_MESSAGE_CONFIG = 32;
    uint8 internal constant SIZE_MESSAGE_ID = 32;
    uint8 internal constant SIZE_MESSAGE_HASH_SUM = 32;
    uint8 internal constant SIZE_DST_CHAIN_DATA_LENGTH = 4;
    uint8 internal constant SIZE_OPERATOR_COUNT = 2;
    uint8 internal constant SIZE_OPERATOR_ENTRY = 32;

    function _decodeCLFMessageReportResponse(
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
                reportType: CLFReportType(reportType),
                operator: operator,
                internalMessageConfig: internalMessageConfig,
                messageId: messageId,
                messageHashSum: messageHashSum,
                dstChainData: dstChainData,
                allowedOperators: allowedOperators
            });
    }
}
