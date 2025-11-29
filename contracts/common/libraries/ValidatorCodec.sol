// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {CodecCommon} from "./CodecCommon.sol";

library ValidatorCodec {
    uint8 internal constant VERSION = 1;

    uint8 internal constant VERSION_OFFSET = 0;
    uint8 internal constant CONFIG_TYPE_OFFSET = VERSION_OFFSET + CodecCommon.UINT8_BYTES_LENGTH;
    uint8 internal constant GAS_LIMIT_OFFSET = CONFIG_TYPE_OFFSET + CodecCommon.UINT8_BYTES_LENGTH;

    enum ConfigType {
        EVM
    }

    function encodeEvmConfig(uint32 gasLimit) internal pure returns (bytes memory) {
        return abi.encodePacked(VERSION, ConfigType.EVM, gasLimit);
    }

    function version(bytes calldata config) internal pure returns (uint8) {
        return uint8(bytes1(config[VERSION_OFFSET:CONFIG_TYPE_OFFSET]));
    }

    function configType(bytes calldata config) internal pure returns (ConfigType) {
        return ConfigType(uint8(bytes1(config[CONFIG_TYPE_OFFSET:GAS_LIMIT_OFFSET])));
    }

    function evmConfigCalldata(bytes calldata config) internal pure returns (uint32) {
        return uint32(bytes4(config[GAS_LIMIT_OFFSET:]));
    }

    function evmConfig(bytes memory config) internal pure returns (uint32) {
        uint32 gasLimit;
        uint256 gasLimitOffset = GAS_LIMIT_OFFSET;

        assembly {
            gasLimit := shr(224, mload(add(add(config, 32), gasLimitOffset)))
        }

        return gasLimit;
    }
}
