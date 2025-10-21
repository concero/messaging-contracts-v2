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

abstract contract ConceroClient is ConceroClientBase {
    using s for s.ConceroClient;

    function _validateMessageReceipt(
        IConceroRouter.MessageReceipt calldata messageReceipt,
        bool[] calldata validationChecks
    ) internal view virtual override {
        _ensureValidations(messageReceipt.dstValidatorLibs, validationChecks);
    }

    function _ensureValidations(
        bytes[] memory dstValidatorLibs,
        bool[] calldata validationChecks
    ) internal view virtual {
        s.ConceroClient storage s_conceroClient = s.client();

        require(
            (s_conceroClient.requiredValidatorsCount == validationChecks.length) &&
                (validationChecks.length == dstValidatorLibs.length),
            ValidatorsConsensusNotReached()
        );

        for (uint256 i; i < dstValidatorLibs.length; ++i) {
            require(validationChecks[i], ValidatorsConsensusNotReached());
            require(
                s_conceroClient.isValidatorAllowed[dstValidatorLibs[i]],
                ValidatorsConsensusNotReached()
            );
        }
    }
}
