// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroClient} from "../interfaces/IConceroClient.sol";
import {IConceroRouter} from "../interfaces/IConceroRouter.sol";
import {ClientBaseStorage as s} from "./libraries/ClientBaseStorage.sol";

abstract contract ConceroClientBase is IConceroClient {
    using s for s.ConceroClientBase;

    address internal immutable i_conceroRouter;

    constructor(address conceroRouter) {
        require(conceroRouter != address(0), InvalidConceroRouter(conceroRouter));
        i_conceroRouter = conceroRouter;
    }

    function conceroReceive(
        bytes32 messageId,
        IConceroRouter.MessageReceipt calldata messageReceipt,
        bool[] calldata validationChecks
    ) external {
        require(msg.sender == i_conceroRouter, InvalidConceroRouter(msg.sender));

        s.ConceroClientBase storage s_conceroClientBase = s.clientBase();

        require(!s_conceroClientBase.isMessageProcessed[messageId], MessageAlreadyProcessed());
        s_conceroClientBase.isMessageProcessed[messageId] = true;

        require(
            s_conceroClientBase.isRelayerAllowed[messageReceipt.dstRelayerLib],
            RelayerNotAllowed(messageReceipt.dstRelayerLib)
        );

        _validateMessageReceipt(messageReceipt, validationChecks);

        _conceroReceive(messageId, messageReceipt);
    }

    function _setIsRelayerAllowed(address relayer, bool isAllowed) internal {
        s.clientBase().isRelayerAllowed[abi.encode(relayer)] = isAllowed;
    }

    function _validateMessageReceipt(
        IConceroRouter.MessageReceipt calldata messageReceipt,
        bool[] calldata validationChecks
    ) internal view virtual;

    function _conceroReceive(
        bytes32 messageId,
        IConceroRouter.MessageReceipt calldata messageReceipt
    ) internal virtual;
}
