// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

library CodecCommon {
    uint8 internal constant UINT8_BYTES_LENGTH = 1;
    uint8 internal constant UINT24_BYTES_LENGTH = 3;
    uint8 internal constant UINT32_BYTES_LENGTH = 4;
    uint8 internal constant UINT64_BYTES_LENGTH = 8;
    uint8 internal constant BYTES32_BYTES_LENGTH = 32;
    uint8 internal constant ADDRESS_BYTES_LENGTH = 20;
    uint8 internal constant LENGTH_BYTES_SIZE = UINT24_BYTES_LENGTH;
}
