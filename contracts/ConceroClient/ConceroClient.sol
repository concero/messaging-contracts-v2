// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "../interfaces/IConceroRouter.sol";
import {ConceroClientBase} from "./ConceroClientBase.sol";
import {ClientStorage as s} from "./libraries/ClientStorage.sol";
import {MessageCodec} from "../common/libraries/MessageCodec.sol";

/// @title ConceroClient
/// @notice Opinionated Concero client implementation with strict validator consensus rules.
/// @dev
/// - Extends `ConceroClientBase` to add:
///   * required validator count enforcement,
///   * per-validator allowlist checks.
/// - A message is accepted only if:
///   * `requiredValidatorsCount` is set and > 0;
///   * `validationChecks.length == validatorLibs.length == requiredValidatorsCount`;
///   * all `validationChecks[i]` are `true`;
///   * all `validatorLibs[i]` are explicitly allowed.
abstract contract ConceroClient is ConceroClientBase {
    using s for s.ConceroClient;
    using MessageCodec for bytes;

    constructor(address conceroRouter) ConceroClientBase(conceroRouter) {}

    /// @notice Validates that a message submission meets the client's consensus policy.
    /// @dev
    /// - Requires that `requiredValidatorsCount` is configured and non-zero.
    /// - Requires that:
    ///   * `requiredValidatorsCount == validationChecks.length`,
    ///   * `validationChecks.length == validatorLibs.length`.
    /// - Iterates over all validators and enforces that:
    ///   * `validationChecks[i] == true`, and
    ///   * `validatorLibs[i]` is in the allowed validators set.
    /// - Reverts with:
    ///   * `RequiredValidatorsCountUnset` if the count is zero,
    ///   * `ValidatorsConsensusNotReached` if any condition fails.
    /// @param validationChecks Boolean array indicating which validators approved the message.
    /// @param validatorLibs Addresses of validator libraries used for validation.
    function _validateMessageSubmission(
        bool[] calldata validationChecks,
        address[] calldata validatorLibs
    ) internal view virtual override {
        s.ConceroClient storage s_conceroClient = s.client();

        uint256 requiredValidatorsCount = s_conceroClient.requiredValidatorsCount;
        require(requiredValidatorsCount != 0, RequiredValidatorsCountUnset());
        require(
            (requiredValidatorsCount == validationChecks.length) &&
                (validationChecks.length == validatorLibs.length),
            ValidatorsConsensusNotReached()
        );

        for (uint256 i; i < validatorLibs.length; ++i) {
            require(validationChecks[i], ValidatorsConsensusNotReached());
            require(
                s_conceroClient.isValidatorAllowed[validatorLibs[i]],
                ValidatorsConsensusNotReached()
            );
        }
    }

    /// @notice Internal helper to allow or disallow a validator library for this client.
    /// @dev
    /// - Typically used by admin functions in inheriting contracts.
    /// - When `isAllowed` is false, messages validated by this library will not be accepted.
    /// @param validator Address of the validator library to configure.
    /// @param isAllowed Boolean flag indicating whether the validator is allowed.
    function _setIsValidatorAllowed(address validator, bool isAllowed) internal {
        s.client().isValidatorAllowed[validator] = isAllowed;
    }

    /// @notice Internal helper to configure the required number of validators.
    /// @dev
    /// - Must be greater than zero to enable message processing.
    /// - All messages must be validated by exactly this many validators.
    /// @param requiredValidatorsCount Number of validators that must approve each message.
    function _setRequiredValidatorsCount(uint256 requiredValidatorsCount) internal {
        s.client().requiredValidatorsCount = requiredValidatorsCount;
    }
}
