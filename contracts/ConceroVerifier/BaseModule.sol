// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroOwnable} from "../Common/ConceroOwnable.sol";
import {OnlyAllowedOperator} from "../Common/Errors.sol";
import {ConceroVerifierStorage as s} from "./ConceroVerifierStorage.sol";

abstract contract BaseModule is ConceroOwnable {
    uint24 internal immutable i_chainSelector;
    address internal immutable i_USDC;

    using s for s.Operator;
    modifier onlyOperator() {
        require(s.operator().isAllowed[msg.sender], OnlyAllowedOperator());
        _;
    }

    constructor(uint24 chainSelector, address USDC) ConceroOwnable() {
        i_chainSelector = chainSelector;
        i_USDC = USDC;
    }
}
