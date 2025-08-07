// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouter} from "./ConceroRouter.sol";
import {GenericStorage} from "./modules/GenericStorage.sol";
import {Namespaces} from "./libraries/Storage.sol";

/**
 * @title ConceroRouterHarness
 * @dev Test harness for ConceroRouter that includes GenericStorage functionality
 * This contract is used only for testing purposes to maintain backward compatibility
 * with tests that rely on GenericStorage functionality.
 */
contract ConceroRouterHarness is ConceroRouter, GenericStorage {
    constructor(
        uint24 chainSelector,
        address conceroPriceFeed,
        address conceroVerifier,
        uint64 conceroVerifierSubId,
        address[4] memory clfSigners
    )
        ConceroRouter(
            chainSelector,
            conceroPriceFeed,
            conceroVerifier,
            conceroVerifierSubId,
            clfSigners
        )
    {}
}
