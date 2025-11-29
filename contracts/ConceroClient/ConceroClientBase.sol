// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {MessageCodec} from "../common/libraries/MessageCodec.sol";
import {ClientStorage as s} from "./libraries/ClientStorage.sol";
import {IConceroClient} from "../interfaces/IConceroClient.sol";
import {IConceroRouter} from "../interfaces/IConceroRouter.sol";

abstract contract ConceroClientBase is IConceroClient {
    using s for s.ConceroClient;
    using MessageCodec for bytes;

    address internal immutable i_conceroRouter;

    constructor(address conceroRouter) {
        require(conceroRouter != address(0), InvalidConceroRouter(conceroRouter));
        i_conceroRouter = conceroRouter;
    }

    function conceroReceive(
        bytes calldata messageReceipt,
        bool[] calldata validationChecks,
        address[] calldata validatorLibs,
        address relayerLib
    ) external {
        require(msg.sender == i_conceroRouter, InvalidConceroRouter(msg.sender));

        s.ConceroClient storage s_conceroClient = s.client();

        require(s_conceroClient.isRelayerLibAllowed[relayerLib], UnauthorizedRelayerLib(relayerLib));

        _validateMessageSubmission(validationChecks, validatorLibs);

        _conceroReceive(messageReceipt);
    }

    function _setIsRelayerLibAllowed(address s_relayer, bool isAllowed) internal {
        s.client().isRelayerLibAllowed[s_relayer] = isAllowed;
    }

    function _validateMessageSubmission(
        bool[] calldata validationChecks,
        address[] calldata validatorLibs
    ) internal view virtual;

    function _conceroReceive(bytes calldata messageReceipt) internal virtual;
}
