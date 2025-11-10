// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouter} from "../../../contracts/ConceroRouter/ConceroRouter.sol";
import {Storage as s} from "../../../contracts/ConceroRouter/libraries/Storage.sol";

contract ConceroRouterCertoraHarness is ConceroRouter {
    using s for s.Router;

    constructor(
        uint24 chainSelector,
        address conceroPriceFeed
    ) ConceroRouter(chainSelector, conceroPriceFeed) {}

    function exposed_setMaxValidatorsCount(uint16 count) external {
        s.router().maxValidatorsCount = count;
    }

    function exposed_setMaxMessageSize(uint64 size) external {
        s.router().maxMessageSize = size;
    }
}
