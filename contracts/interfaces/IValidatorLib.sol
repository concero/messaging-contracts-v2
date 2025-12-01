// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "./IConceroRouter.sol";

/// @title IValidatorLib
/// @notice Interface for validator libraries used by the Concero router to validate cross-chain messages.
/// @dev
/// - Implementations are responsible for:
///   * determining whether a message + proof pair is valid (`isValid`),
///   * pricing validation work (`getFee`, `getFeeAndValidatorConfig`),
///   * providing per-message validator configuration,
///   * reporting which fee tokens they support.
interface IValidatorLib {
    /**
     * @notice Verifies that a message and its validation data are valid.
     * @dev
     * - Called by the Concero router on the destination chain via a `staticcall`.
     * - Implementations should:
     *   * decode `messageReceipt`,
     *   * verify `validation` (e.g. signature / proof),
     *   * return `true` if the message is considered valid, `false` otherwise.
     * @param messageReceipt Packed message receipt produced on the source chain.
     * @param validation Validator-specific proof bytes (e.g. signatures, commitments, etc.).
     * @return True if the validation passes, false otherwise.
     */
    function isValid(
        bytes calldata messageReceipt,
        bytes calldata validation
    ) external view returns (bool);

    /**
     * @notice Returns the fee required by this validator to validate a given message.
     * @dev
     * - The implementation may consider:
     *   * destination chain,
     *   * payload size,
     *   * security parameters,
     *   * and any other fields from `messageRequest`.
     * - This function is primarily a convenience wrapper; see `getFeeAndValidatorConfig`.
     * @param messageRequest Full message request being sent via the router.
     * @return Fee amount denominated in `messageRequest.feeToken`.
     */
    function getFee(
        IConceroRouter.MessageRequest calldata messageRequest
    ) external view returns (uint256);

    /**
     * @notice Returns the validator configuration to be embedded in a message.
     * @dev
     * - The returned config is stored in the message receipt and later used on the
     *   destination chain (e.g. to specify gas limits, quorum parameters, etc.).
     * @param messageRequest Full message request being sent via the router.
     * @return Validator-specific configuration encoded as bytes.
     */
    function getValidatorConfig(
        IConceroRouter.MessageRequest calldata messageRequest
    ) external view returns (bytes memory);

    /**
     * @notice Returns both the validation fee and the validator configuration.
     * @dev
     * - Convenience function that allows computing fee and config in a single call.
     * - The Concero router will typically use this function when constructing messages.
     * @param messageRequest Full message request being sent via the router.
     * @return fee Fee amount denominated in `messageRequest.feeToken`.
     * @return validatorConfig Validator-specific configuration encoded as bytes.
     */
    function getFeeAndValidatorConfig(
        IConceroRouter.MessageRequest calldata messageRequest
    ) external view returns (uint256, bytes memory);

    /**
     * @notice Indicates whether a given fee token is supported by this validator lib.
     * @dev
     * - The Concero router may rely on this to ensure that `feeToken` is acceptable
     *   before selecting this validator for a message.
     * @param feeToken Address of the fee token (use address(0) for native token).
     * @return True if the fee token is supported, false otherwise.
     */
    function isFeeTokenSupported(address feeToken) external view returns (bool);
}
