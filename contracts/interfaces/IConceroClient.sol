// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "./IConceroRouter.sol";

/// @title IConceroClient
/// @notice Interface for Concero-enabled client contracts that can receive cross-chain messages.
/// @dev
/// - Implementing contracts are expected to be called only by a trusted ConceroRouter.
/// - They should perform additional validation and authorization before acting on messages.
interface IConceroClient {
    /// @notice Thrown when an invalid or unexpected Concero router address is used.
    /// @param router Address of the router that was rejected.
    error InvalidConceroRouter(address router);
    /// @notice Thrown when a relayer library is not authorized for this client.
    /// @param dstRelayerLib Address of the unapproved relayer library.
    error UnauthorizedRelayerLib(address dstRelayerLib);
    /// @notice Thrown when validator checks do not meet the required consensus policy.
    /// @dev For example, not enough validators returned a positive validation result.
    error ValidatorsConsensusNotReached();
    /// @notice Thrown when the required validators count has not been configured.
    /// @dev Implementations may rely on this to ensure proper security configuration.
    error RequiredValidatorsCountUnset();

    /// @dev
    /// - Validates that the caller is the configured router.
    /// - Checks that the `relayerLib` has been explicitly allowed.
    /// - Delegates validation logic to `_validateMessageSubmission`.
    /// - Delegates message handling logic to `_conceroReceive`.
    /// @param messageReceipt Encoded message receipt containing routing and payload data.
    /// @param validationChecks Boolean array indicating which validators approved the message.
    /// @param validatorLibs Validator libraries used to produce the validations.
    /// @param relayerLib Relayer library that submitted the message to the router.
    function conceroReceive(
        bytes calldata messageReceipt,
        bool[] calldata validationChecks,
        address[] calldata validatorLibs,
        address relayerLib
    ) external;
}
