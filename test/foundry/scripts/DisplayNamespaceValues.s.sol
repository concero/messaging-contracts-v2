// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/console.sol";
import {Script} from "forge-std/src/Script.sol";

import {Namespaces as ConceroRouterNamespaces} from "contracts/ConceroRouter/libraries/Storage.sol";
import {Namespaces as ConceroVerifierNamespaces} from "contracts/ConceroVerifier/libraries/Storage.sol";

contract DisplayNamespaceValues is Script {
    function run() public {
        bytes32 conceroRouterRouter = ConceroRouterNamespaces.ROUTER;
        bytes32 conceroRouterOperator = ConceroRouterNamespaces.OPERATOR;
        bytes32 conceroRouterPriceFeed = ConceroRouterNamespaces.PRICEFEED;

        bytes32 conceroVerifierVerifier = ConceroVerifierNamespaces.VERIFIER;
        bytes32 conceroVerifierOperator = ConceroVerifierNamespaces.OPERATOR;
        bytes32 conceroVerifierPriceFeed = ConceroVerifierNamespaces.PRICEFEED;

        console.logString("ConceroRouter::Router:");
        console.logBytes32(conceroRouterRouter);

        console.logString("ConceroRouter::Operator:");
        console.logBytes32(conceroRouterOperator);

        console.logString("ConceroRouter::PriceFeed:");
        console.logBytes32(conceroRouterPriceFeed);

        console.logString("ConceroVerifier::Verifier:");
        console.logBytes32(conceroVerifierVerifier);

        console.logString("ConceroVerifier::Operator:");
        console.logBytes32(conceroVerifierOperator);

        console.logString("ConceroVerifier::PriceFeed:");
        console.logBytes32(conceroVerifierPriceFeed);
    }
}
