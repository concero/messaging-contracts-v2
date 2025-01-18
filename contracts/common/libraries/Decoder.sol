//SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;
import {Types} from "../../ConceroVerifier/libraries/Types.sol";

library MessageConstants {
    uint8 internal constant SIZE_VERSION = 1;
    uint8 internal constant SIZE_REPORT_TYPE = 1;
    uint8 internal constant SIZE_OPERATOR = 32;
    uint8 internal constant SIZE_INTERNAL_MESSAGE_CONFIG = 32;
    uint8 internal constant SIZE_MESSAGE_ID = 32;
    uint8 internal constant SIZE_MESSAGE_HASH_SUM = 32;
    uint8 internal constant SIZE_DST_CHAIN_DATA_LENGTH = 4;
    uint8 internal constant SIZE_OPERATOR_COUNT = 2;
    uint8 internal constant SIZE_OPERATOR_ENTRY = 32;
}

library OperatorConstants {
    uint8 internal constant SIZE_VERSION = 1;
    uint8 internal constant SIZE_REPORT_TYPE = 1;
    uint8 internal constant SIZE_OPERATOR = 32;
    uint8 internal constant SIZE_CHAIN_TYPES_LENGTH = 4;
    uint8 internal constant SIZE_OPERATOR_ADDRESSES_LENGTH = 4;
    uint8 internal constant SIZE_OPERATOR_ACTIONS_LENGTH = 4;
}

library Decoder {
    function _decodeCLFMessageReportResponse(
        bytes memory response
    ) internal pure returns (Types.MessageReportResult memory) {
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

        uint8 size_version = MessageConstants.SIZE_VERSION;
        uint8 size_report_type = MessageConstants.SIZE_REPORT_TYPE;
        uint8 size_operator = MessageConstants.SIZE_OPERATOR;
        uint8 size_internal_message_config = MessageConstants.SIZE_INTERNAL_MESSAGE_CONFIG;
        uint8 size_message_id = MessageConstants.SIZE_MESSAGE_ID;
        uint8 size_message_hash_sum = MessageConstants.SIZE_MESSAGE_HASH_SUM;
        uint8 size_dst_chain_data_length = MessageConstants.SIZE_DST_CHAIN_DATA_LENGTH;
        uint8 size_operator_count = MessageConstants.SIZE_OPERATOR_COUNT;
        uint8 size_operator_entry = MessageConstants.SIZE_OPERATOR_ENTRY;

        assembly {
            // Read version (1 byte) and reportType (1 byte)
            version := byte(0, mload(add(response, offset)))
            reportType := byte(1, mload(add(response, offset)))
            offset := add(offset, size_version)
            offset := add(offset, size_report_type)

            // Read operator (20 bytes padded to 32 bytes)
            operator := shr(96, mload(add(response, offset)))
            offset := add(offset, size_operator)

            // Read internalMessageConfig (32 bytes)
            internalMessageConfig := mload(add(response, offset))
            offset := add(offset, size_internal_message_config)

            // Read messageId (32 bytes)
            messageId := mload(add(response, offset))
            offset := add(offset, size_message_id)

            // Read messageHashSum (32 bytes)
            messageHashSum := mload(add(response, offset))
            offset := add(offset, size_message_hash_sum)

            // Read dstChainData length (4 bytes as uint32)
            dstChainDataLength := shr(224, mload(add(response, offset)))
            offset := add(offset, size_dst_chain_data_length)
        }

        dstChainData = new bytes(dstChainDataLength);
        for (uint256 i = 0; i < dstChainDataLength; i++) {
            dstChainData[i] = response[offset + i];
        }
        offset += dstChainDataLength;

        assembly {
            allowedOperatorsCount := shr(240, mload(add(response, offset)))
            offset := add(offset, size_operator_count)
        }

        rawAllowedOperators = new bytes32[](allowedOperatorsCount);
        for (uint16 i = 0; i < allowedOperatorsCount; i++) {
            assembly {
                let operatorValue := mload(add(response, offset))
                mstore(add(add(rawAllowedOperators, 0x20), mul(i, 0x20)), operatorValue)
            }
            offset += size_operator_entry;
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
            Types.MessageReportResult({
                version: version,
                reportType: Types.CLFReportType(reportType),
                operator: operator,
                internalMessageConfig: internalMessageConfig,
                messageId: messageId,
                messageHashSum: messageHashSum,
                dstChainData: dstChainData,
                allowedOperators: allowedOperators
            });
    }

    function _decodeCLFOperatorRegistrationReport(
        bytes memory response
    ) internal pure returns (Types.OperatorRegistrationResult memory) {
        Types.OperatorRegistrationResult memory result;
        uint256 offset = 0;
        uint32 chainTypesLength;
        uint32 operatorAddressesLength;
        uint32 operatorActionsLength;

        uint8 size_version = OperatorConstants.SIZE_VERSION;
        uint8 size_report_type = OperatorConstants.SIZE_REPORT_TYPE;
        uint8 size_operator = OperatorConstants.SIZE_OPERATOR;
        uint8 size_chain_types_length = OperatorConstants.SIZE_CHAIN_TYPES_LENGTH;
        uint8 size_operator_actions_length = OperatorConstants.SIZE_OPERATOR_ACTIONS_LENGTH;
        uint8 size_operator_addresses_length = OperatorConstants.SIZE_OPERATOR_ADDRESSES_LENGTH;

        assembly {
            let dataWord := mload(add(response, add(32, offset)))
            result := mload(0x40)
            mstore8(result, byte(0, dataWord))
            mstore8(add(result, 1), byte(1, dataWord))
            offset := add(offset, add(size_version, size_report_type))

            mstore(add(result, 32), shr(96, mload(add(response, add(32, offset)))))
            offset := add(offset, size_operator)

            chainTypesLength := shr(224, mload(add(response, add(32, offset))))
            offset := add(offset, size_chain_types_length)
        }

        result.operatorChains = new Types.ChainType[](chainTypesLength);
        for (uint256 i = 0; i < chainTypesLength; i++) {
            result.operatorChains[i] = Types.ChainType(uint8(response[offset + i]));
        }
        offset += chainTypesLength;

        assembly {
            operatorActionsLength := shr(224, mload(add(response, add(32, offset))))
            offset := add(offset, size_operator_actions_length)
        }

        result.operatorActions = new Types.OperatorRegistrationAction[](operatorActionsLength);
        for (uint256 i = 0; i < operatorActionsLength; i++) {
            result.operatorActions[i] = Types.OperatorRegistrationAction(
                uint8(response[offset + i])
            );
        }
        offset += operatorActionsLength;

        assembly {
            operatorAddressesLength := shr(224, mload(add(response, add(32, offset))))
            offset := add(offset, size_operator_addresses_length)
        }

        result.operatorAddresses = new bytes[](operatorAddressesLength);
        uint256 currentOffset = offset;
        for (uint256 i = 0; i < operatorAddressesLength; i++) {
            uint16 addressLength;
            assembly {
                addressLength := shr(240, mload(add(response, currentOffset)))
            }
            currentOffset += 2;

            bytes memory addressBytes = new bytes(addressLength);
            for (uint256 j = 0; j < addressLength; j++) {
                addressBytes[j] = response[currentOffset + j];
            }
            result.operatorAddresses[i] = addressBytes;
            currentOffset += addressLength;
        }
        offset = currentOffset;

        return result;
    }
}
