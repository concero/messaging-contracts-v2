// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Errors} from "../libraries/Errors.sol";
import {Storage as s} from "../libraries/Storage.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";
import {ConceroOwnable} from "../../common/ConceroOwnable.sol";
import {IConceroPriceFeed} from "../../interfaces/IConceroPriceFeed.sol";

abstract contract Base is ConceroOwnable {
    uint24 internal immutable i_chainSelector;
    IConceroPriceFeed internal immutable i_conceroPriceFeed;

    using s for s.Operator;
    modifier onlyOperator() {
        require(s.operator().isRegistered[msg.sender], Errors.UnauthorizedOperator());
        _;
    }

    constructor(uint24 chainSelector, address conceroPriceFeed) ConceroOwnable() {
        require(conceroPriceFeed != address(0), CommonErrors.InvalidAddress());
        i_chainSelector = chainSelector;
        i_conceroPriceFeed = IConceroPriceFeed(conceroPriceFeed);
    }
}
