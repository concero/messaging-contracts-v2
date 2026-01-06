// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouter} from "contracts/ConceroRouter/ConceroRouter.sol";
import {Storage as s} from "contracts/ConceroRouter/libraries/Storage.sol";

/**
 * @title ConceroRouterHarness
 */
contract ConceroRouterHarness is ConceroRouter {
    using s for s.Router;

    constructor(uint24 chainSelector) ConceroRouter(chainSelector) {}

    function getNonce(
        address sender,
        uint24 srcChainSelector,
        uint24 dstChainSelector
    ) external view returns (uint256) {
        return s.router().nonce[sender][srcChainSelector][dstChainSelector];
    }
}
