// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "./IConceroRouter.sol";

interface IValidatorLib {
    error InvalidChainSelector();

    function isValid(
        bytes calldata messageReceipt,
        bytes calldata validation
    ) external view returns (bool);

    function getFee(
        IConceroRouter.MessageRequest calldata messageRequest
    ) external view returns (uint256);
}
