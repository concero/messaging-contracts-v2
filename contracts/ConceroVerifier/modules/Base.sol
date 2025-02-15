// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroOwnable} from "../../common/ConceroOwnable.sol";
import {Errors} from "../libraries/Errors.sol";

import {Storage as s} from "../libraries/Storage.sol";

abstract contract Base is ConceroOwnable {
    uint24 internal immutable i_chainSelector;
    address internal immutable i_USDC;

    using s for s.Operator;
    modifier onlyOperator() {
        require(s.operator().isRegistered[msg.sender], Errors.UnauthorizedOperator());
        _;
    }

    constructor(uint24 chainSelector, address USDC) ConceroOwnable() {
        i_chainSelector = chainSelector;
        i_USDC = USDC;
    }
}
