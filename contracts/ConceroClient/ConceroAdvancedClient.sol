// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {ConceroClientBase} from "./ConceroClientBase.sol";
import {ClientAdvancedStorage as s} from "./libraries/ClientAdvancedStorage.sol";
import {IConceroRouter} from "../interfaces/IConceroRouter.sol";
import {MessageCodec} from "../common/libraries/MessageCodec.sol";

abstract contract ConceroAdvancedClient is ConceroClientBase {
    using s for s.AdvancedClient;
    using MessageCodec for bytes;

    function _validateMessageReceipt(
        bytes calldata messageReceipt,
        bool[] calldata validationChecks
    ) internal view virtual override {
        _ensureValidationsWeight(messageReceipt.evmDstValidatorLibs(), validationChecks);
    }

    function _ensureValidationsWeight(
        address[] memory dstValidatorLibs,
        bool[] calldata validationChecks
    ) internal view virtual {
        s.AdvancedClient storage s_advancedClient = s.advancedClient();
        uint256 totalWeight;

        for (uint256 i; i < dstValidatorLibs.length && i < validationChecks.length; ++i) {
            for (uint256 k; k < dstValidatorLibs.length; ++k) {
                if (i == k) continue;
                require(
                    dstValidatorLibs[i] != dstValidatorLibs[k],
                    ValidatorsConsensusNotReached()
                );
            }

            if (validationChecks[i]) {
                totalWeight += s_advancedClient.validatorWeights[dstValidatorLibs[i]];
            }
        }

        require(totalWeight >= s_advancedClient.requiredWeight, ValidatorsConsensusNotReached());
    }
}
