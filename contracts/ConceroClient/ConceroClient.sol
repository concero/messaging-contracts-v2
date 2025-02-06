// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IConceroClient} from "../interfaces/IConceroClient.sol";

abstract contract ConceroClient is IConceroClient {
    error InvalidRouter(address router);

    uint8 internal constant VERSION = 1;
    address internal immutable i_conceroRouter;
    uint24 internal immutable i_chainSelector;

    constructor(address router, uint24 chainSelector) {
        require(router != address(0), InvalidRouter(router));
        i_conceroRouter = router;
        i_chainSelector = chainSelector;
    }

    function conceroReceive(bytes32 messageId, bytes calldata message) external {
        require(msg.sender == i_conceroRouter, InvalidRouter(msg.sender));
        _conceroReceive(messageId, message);
    }

    function _conceroReceive(bytes32 messageId, bytes calldata message) internal virtual;
}
