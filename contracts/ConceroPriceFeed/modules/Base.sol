// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

abstract contract Base {
    uint24 internal immutable i_chainSelector;

    constructor(uint24 chainSelector) {
        i_chainSelector = chainSelector;
    }
}
