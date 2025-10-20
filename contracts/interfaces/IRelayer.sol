// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IConceroRouter} from "./IConceroRouter.sol";

interface IRelayer {
    function submitMessage(
        bytes32 messageId,
        IConceroRouter.MessageReceipt calldata messageReceipt,
        bool[] calldata validations
    ) external;
}
