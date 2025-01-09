// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ClientMessage} from "../Common/MessageTypes.sol";

interface IConceroClient {
    function ConceroReceive(ClientMessage calldata message) external;
}
