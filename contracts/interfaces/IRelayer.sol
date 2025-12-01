// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "./IConceroRouter.sol";

interface IRelayer {
    error MessageSubmissionAlreadyReceived(bytes32 messageId, bytes32 messageSubmissionHash);
    error InvalidReceiver();
    error InvalidDstChainSelector(uint24 received, uint24 expexted);
    error MessageAlreadyProcessed(bytes32 messageHash);
    error MessageSubmissionAlreadyProcessed(bytes32 messageSubmissionHash);
    error InvalidValidationsCount(uint256 validatorLibsCount, uint256 validationsCount);

    /// @notice Emitted when a relayer successfully withdraws its accumulated fees.
    /// @param realayer Address of the relayer (or relayer lib) withdrawing the fees.
    /// @param token Address of the fee token (use address(0) for native token).
    /// @param amount Amount of fees withdrawn.
    event RelayerFeeWithdrawn(address indexed realayer, address indexed token, uint256 amount);

    /// @notice Submits a validated message to the destination chain for execution.
    /// @dev
    /// - Called by a relayer once it has the message receipt and validator proofs.
    /// - Performs:
    ///   * destination chain check,
    ///   * validation count consistency check,
    ///   * deduplication of message (not processed before),
    ///   * relayer authorization via `IRelayerLib.validate`,
    ///   * validator checks via `_performValidationChecks`.
    /// - Emits `ConceroMessageReceived` and attempts delivery via `_deliverMessage`.
    /// @param messageReceipt Packed encoded message receipt.
    /// @param validations Per-validator proof blobs corresponding to `validatorLibs`.
    /// @param validatorLibs Validator libraries to be used on this destination chain.
    /// @param relayerLib Relayer library that authorized the relayer and prices delivery.
    function submitMessage(
        bytes calldata messageReceipt,
        bytes[] calldata validations,
        address[] calldata validatorLibs,
        address relayerLib
    ) external;

    /**
     * @notice Withdraws the Relayer fees earned by the router.
     */
    function withdrawRelayerFee(address[] calldata tokens) external;
}
