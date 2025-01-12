// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {MessageEventParams} from "../Common/MessageTypes.sol";

interface IConceroRouter {
    event ConceroMessageSent(bytes32 indexed messageId, MessageEventParams messageEventParams);
    event ConceroMessageReceived(bytes32 indexed id, MessageEventParams message);
}
