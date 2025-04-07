// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Storage as s} from "../../ConceroRouter/libraries/Storage.sol";

library SupportedChains {
    using s for s.Router;

    error UnsupportedChainSelector();


    function isChainSupported(uint24 chainSelector) internal view returns (bool) {
        return s.router().isChainSupported[chainSelector];
    }

    function maxConfirmations(uint24 chainSelector) internal pure returns (uint16) {
        return uint16(100);
    }
}
