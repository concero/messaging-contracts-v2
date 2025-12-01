// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {CodecCommon} from "./CodecCommon.sol";

/// @title ValidatorCodec
/// @notice Utility library for encoding and decoding validator configuration blobs.
/// @dev
/// - Provides a compact format for validator configs with:
///   * version byte,
///   * config type (e.g. EVM),
///   * gas limit or other config-specific data.
/// - Used by validator libraries and the router to pass per-validator settings.
library ValidatorCodec {
    uint8 internal constant VERSION = 1;

    uint8 internal constant VERSION_OFFSET = 0;
    uint8 internal constant CONFIG_TYPE_OFFSET = VERSION_OFFSET + CodecCommon.UINT8_BYTES_LENGTH;
    uint8 internal constant GAS_LIMIT_OFFSET = CONFIG_TYPE_OFFSET + CodecCommon.UINT8_BYTES_LENGTH;

    enum ConfigType {
        EVM
    }

    /// @notice Encodes an EVM validator configuration with a gas limit.
    /// @dev
    /// Layout:
    /// - [0]      : VERSION (uint8)
    /// - [1]      : ConfigType.EVM (uint8)
    /// - [2:6]    : gasLimit (uint32)
    ///
    /// @param gasLimit Gas limit to be used when calling the validator on-chain.
    /// @return Encoded configuration bytes for an EVM validator.
    function encodeEvmConfig(uint32 gasLimit) internal pure returns (bytes memory) {
        return abi.encodePacked(VERSION, ConfigType.EVM, gasLimit);
    }

    /// @notice Extracts the version from an encoded validator config.
    /// @param config Encoded validator configuration bytes.
    /// @return Version byte stored in the config.
    function version(bytes calldata config) internal pure returns (uint8) {
        return uint8(bytes1(config[VERSION_OFFSET:CONFIG_TYPE_OFFSET]));
    }

    function configType(bytes calldata config) internal pure returns (ConfigType) {
        return ConfigType(uint8(bytes1(config[CONFIG_TYPE_OFFSET:GAS_LIMIT_OFFSET])));
    }

    function evmConfigCalldata(bytes calldata config) internal pure returns (uint32) {
        return uint32(bytes4(config[GAS_LIMIT_OFFSET:]));
    }

    /// @notice Reads the EVM gas limit from a validator config (memory version).
    /// @dev
    /// - Assumes the config has `ConfigType.EVM`.
    /// - Uses inline assembly for an efficient read from memory.
    ///
    /// @param config Encoded validator configuration bytes (memory).
    /// @return gasLimit Decoded gas limit value.
    function evmConfig(bytes memory config) internal pure returns (uint32) {
        uint32 gasLimit;
        uint256 gasLimitOffset = GAS_LIMIT_OFFSET;

        assembly {
            gasLimit := shr(224, mload(add(add(config, 32), gasLimitOffset)))
        }

        return gasLimit;
    }
}
