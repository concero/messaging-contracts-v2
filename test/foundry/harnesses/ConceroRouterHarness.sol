// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouter} from "../../../contracts/ConceroRouter/ConceroRouter.sol";

/**
 * @title ConceroRouterHarness
 */
contract ConceroRouterHarness is ConceroRouter {
    constructor(
        uint24 chainSelector,
        address conceroPriceFeed
    ) ConceroRouter(chainSelector, conceroPriceFeed) {}
}
