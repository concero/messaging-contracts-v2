// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "./IConceroRouter.sol";

interface IConceroClient {
    error InvalidConceroRouter(address router);
    error RelayerNotAllowed(address dstRelayerLib);
    error ValidatorsConsensusNotReached();
    error RequiredValidatorsCountUnset();

    function conceroReceive(
        bytes calldata messageReceipt,
        bool[] calldata validationChecks,
        address[] calldata validatorLibs,
        address relayerLib
    ) external;
}
