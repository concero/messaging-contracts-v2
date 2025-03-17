// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IConceroClientErrors} from "./IConceroClientErrors.sol";

interface IConceroClient is IConceroClientErrors {
    function conceroReceive(
        bytes32 messageId,
        uint24 chainSelector,
        bytes calldata sender,
        bytes calldata message
    ) external;
}
