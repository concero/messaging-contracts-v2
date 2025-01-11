// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ClientMessageRequest} from "../Common/MessageTypes.sol";

interface IConceroRouter {
    event ConceroMessageSent(bytes32 indexed id, ClientMessageRequest message);
    event ConceroMessageReceived(bytes32 indexed id, InternalMessage message);
}
