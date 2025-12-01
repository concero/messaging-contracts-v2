// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "./IConceroRouter.sol";

/// @title IRelayerLib
/// @notice Interface for relayer pricing and authorization logic used by the Concero router.
/// @dev
/// - Implementations are responsible for:
///   * pricing message delivery (`getFee`),
///   * validating that a given `relayer` is allowed to submit a specific message (`validate`),
///   * indicating which fee tokens they support (`isFeeTokenSupported`).
interface IRelayerLib {
    error InvalidRelayer(address relayer);
    /// @notice Thrown when an unsupported or malformed operator config type is encountered.
    /// @param InvalidOperatorConfigType Numeric type identifier that was rejected.
    error InvalidOperatorConfigType(uint8);

    /**
     * @notice Returns the relayer fee required to deliver a given message.
     * @dev
     * - The implementation can base pricing on:
     *   * destination chain,
     *   * payload size,
     *   * gas limits,
     *   * and any operator-specific configuration passed in `operatorConfig`.
     * - Called by the Concero router when computing the total message fee.
     * @param messageRequest Full message request being sent via the router.
     * @param operatorConfig Operator-specific configuration blobs (already resolved for this relayer).
     * @return The fee amount denominated in `messageRequest.feeToken`.
     */
    function getFee(
        IConceroRouter.MessageRequest calldata messageRequest,
        bytes[] calldata operatorConfig
    ) external view returns (uint256);

    /**
     * @notice Validates that the given `relayer` is authorized to deliver `messageReceipt`.
     * @dev
     * - Called by the Concero router during message submission on the destination chain.
     * - Implementations can enforce:
     *   * allowlists / blocklists,
     *   * staking requirements,
     *   * or other relayer-specific eligibility rules.
     * - MUST revert with `InvalidRelayer` if the relayer is not authorized.
     * @param messageReceipt Packed message receipt produced on the source chain.
     * @param relayer Address of the relayer submitting the message.
     */
    function validate(bytes calldata messageReceipt, address relayer) external;

    /**
     * @notice Indicates whether a given fee token is supported by this relayer lib.
     * @dev
     * - The Concero router may rely on this to ensure that `feeToken` is acceptable
     *   before trying to use this relayer lib for a message.
     * @param feeToken Address of the fee token (use address(0) for native token).
     * @return True if the token is supported, false otherwise.
     */
    function isFeeTokenSupported(address feeToken) external view returns (bool);
}
