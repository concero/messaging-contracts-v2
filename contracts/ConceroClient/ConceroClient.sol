// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IConceroClient} from "../interfaces/IConceroClient.sol";

abstract contract ConceroClient is IConceroClient {
    error InvalidConceroRouter(address router);

    uint8 internal constant VERSION = 1;
    address internal immutable i_conceroRouter;
    uint24 internal immutable i_chainSelector;

    constructor(address conceroRouter, uint24 chainSelector) {
        require(conceroRouter != address(0), InvalidConceroRouter(conceroRouter));
        i_conceroRouter = conceroRouter;
        i_chainSelector = chainSelector;
    }

    function conceroReceive(bytes32 messageId, bytes calldata message) external {
        require(msg.sender == i_conceroRouter, InvalidConceroRouter(msg.sender));
        _conceroReceive(messageId, message);
    }

    function _conceroReceive(bytes32 messageId, bytes calldata message) internal virtual;
}
