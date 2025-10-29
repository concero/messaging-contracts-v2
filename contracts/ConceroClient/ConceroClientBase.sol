// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {MessageCodec} from "../common/libraries/MessageCodec.sol";
import {ClientBaseStorage as s} from "./libraries/ClientBaseStorage.sol";
import {IConceroClient} from "../interfaces/IConceroClient.sol";
import {IConceroRouter} from "../interfaces/IConceroRouter.sol";

abstract contract ConceroClientBase is IConceroClient {
    using s for s.ConceroClientBase;
    using MessageCodec for bytes;

    address internal immutable i_conceroRouter;

    constructor(address conceroRouter) {
        require(conceroRouter != address(0), InvalidConceroRouter(conceroRouter));
        i_conceroRouter = conceroRouter;
    }

    function conceroReceive(
        bytes calldata messageReceipt,
        bool[] calldata validationChecks
    ) external {
        require(msg.sender == i_conceroRouter, InvalidConceroRouter(msg.sender));

        s.ConceroClientBase storage s_conceroClientBase = s.clientBase();

        //        require(!s_conceroClientBase.isMessageProcessed[messageId], MessageAlreadyProcessed());
        //        s_conceroClientBase.isMessageProcessed[messageId] = true;

        require(
            s_conceroClientBase.isRelayerAllowed[messageReceipt.emvDstRelayerLib()],
            RelayerNotAllowed(messageReceipt.emvDstRelayerLib())
        );

        _validateMessageReceipt(messageReceipt, validationChecks);

        _conceroReceive(messageReceipt);
    }

    function _setIsRelayerAllowed(address relayer, bool isAllowed) internal {
        s.clientBase().isRelayerAllowed[relayer] = isAllowed;
    }

    function _validateMessageReceipt(
        bytes calldata messageReceipt,
        bool[] calldata validationChecks
    ) internal view virtual;

    function _conceroReceive(bytes calldata messageReceipt) internal virtual;
}
