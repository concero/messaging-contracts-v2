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

abstract contract ConceroClient is ConceroClientBase {
    using s for s.ConceroClient;
    using MessageCodec for bytes;

    constructor(address conceroRouter) ConceroClientBase(conceroRouter) {}

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

    function _setIsValidatorAllowed(address validator, bool isAllowed) internal {
        s.client().isValidatorAllowed[validator] = isAllowed;
    }

    function _setRequiredValidatorsCount(uint256 requiredValidatorsCount) internal {
        s.client().requiredValidatorsCount = requiredValidatorsCount;
    }
}
