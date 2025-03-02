// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroOwnable} from "../../common/ConceroOwnable.sol";

abstract contract Base is ConceroOwnable {
    uint24 internal immutable i_chainSelector;
    address internal immutable i_USDC;

    constructor(uint24 chainSelector, address USDC) ConceroOwnable() {
        i_chainSelector = chainSelector;
        i_USDC = USDC;
    }
}
