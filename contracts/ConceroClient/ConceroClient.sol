// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroClient} from "../interfaces/IConceroClient.sol";

abstract contract ConceroClient is IConceroClient {
    error InvalidConceroRouter(address router);

    uint8 internal constant VERSION = 1;
    address internal immutable i_conceroRouter;

    constructor(address conceroRouter) {
        require(conceroRouter != address(0), InvalidConceroRouter(conceroRouter));
        i_conceroRouter = conceroRouter;
    }

    function conceroReceive(
        bytes32 messageId,
        uint24 srcChainSelector,
        bytes calldata sender,
        bytes calldata message
    ) external {
        require(msg.sender == i_conceroRouter, InvalidConceroRouter(msg.sender));
        _conceroReceive(messageId, srcChainSelector, sender, message);
    }

    function _conceroReceive(
        bytes32 messageId,
        uint24 srcChainSelector,
        bytes calldata sender,
        bytes calldata message
    ) internal virtual;
}
