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

    /// @notice Address of the ConceroRouter contract this client trusts for message delivery.
    /// @dev All `conceroReceive` calls must come from this address.
    address internal immutable i_conceroRouter;

    /// @notice Initializes the Concero client base with a router address.
    /// @dev Reverts if `conceroRouter` is the zero address.
    /// @param conceroRouter Address of the ConceroRouter contract on this chain.
    constructor(address conceroRouter) {
        require(conceroRouter != address(0), InvalidConceroRouter(conceroRouter));
        i_conceroRouter = conceroRouter;
    }

    /// @inheritdoc IConceroClient
    function conceroReceive(
        bytes calldata messageReceipt,
        bool[] calldata validationChecks,
        address[] calldata validatorLibs,
        address relayerLib
    ) external {
        require(msg.sender == i_conceroRouter, InvalidConceroRouter(msg.sender));

        s.ConceroClient storage s_conceroClient = s.client();

        require(
            s_conceroClient.isRelayerLibAllowed[relayerLib],
            UnauthorizedRelayerLib(relayerLib)
        );

        _validateMessageSubmission(validationChecks, validatorLibs);

        _conceroReceive(messageReceipt);
    }

    /// @notice Internal helper to set whether a relayer library is allowed to deliver messages.
    /// @dev Typically used by inheriting contracts' admin functions.
    /// @param s_relayer Address of the relayer library.
    /// @param isAllowed Boolean flag indicating if the relayer lib is allowed.
    function _setIsRelayerLibAllowed(address s_relayer, bool isAllowed) internal {
        s.client().isRelayerLibAllowed[s_relayer] = isAllowed;
    }

    /// @notice Hook for implementing custom validation policy over validator checks.
    /// @dev
    /// - Must be implemented by inheriting contracts.
    /// - Common patterns:
    ///   * require at least N validators to have `validationChecks[i] == true`,
    ///   * enforce specific validatorLibs or quorum logic.
    /// @param validationChecks Boolean array with per-validator validation result.
    /// @param validatorLibs Array of validator library addresses used to validate the message.
    function _validateMessageSubmission(
        bool[] calldata validationChecks,
        address[] calldata validatorLibs
    ) internal view virtual;

    /// @notice Hook for processing the message once it has passed all validations.
    /// @dev
    /// - Must be implemented by inheriting contracts.
    /// - Should decode `messageReceipt` and execute the desired business logic.
    /// @param messageReceipt Encoded message receipt payload delivered by the router.
    function _conceroReceive(bytes calldata messageReceipt) internal virtual;
}
