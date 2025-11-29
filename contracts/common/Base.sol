// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {IConceroPriceFeed} from "contracts/interfaces/IConceroPriceFeed.sol";

abstract contract Base {
    uint24 internal immutable i_chainSelector;
    IConceroPriceFeed internal immutable i_conceroPriceFeed;

    constructor(uint24 chainSelector, address conceroPriceFeed) {
        require(conceroPriceFeed != address(0), CommonErrors.InvalidAddress());
        i_chainSelector = chainSelector;
        i_conceroPriceFeed = IConceroPriceFeed(conceroPriceFeed);
    }
}
