// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroClient} from "../interfaces/IConceroClient.sol";
import {IConceroRouter} from "../interfaces/IConceroRouter.sol";
import {Storage as s} from "./libraries/Storage.sol";

abstract contract ConceroClient is IConceroClient {
    using s for s.ConceroClient;

    error InvalidConceroRouter(address router);
    error MessageAlreadyProcessed();
    error ValidatorsConsensusNotReached();
    error ZeroMessageType();
    error RelayerNotAllowed(bytes dstRelayerLib);
    error InvalidSrcChainData();

    address internal immutable i_conceroRouter;

    constructor(address conceroRouter) {
        require(conceroRouter != address(0), InvalidConceroRouter(conceroRouter));
        i_conceroRouter = conceroRouter;
    }

    function conceroReceive(
        bytes32 messageId,
        IConceroRouter.MessageReceipt calldata messageReceipt,
        bool[] calldata validationChecks
    ) external {
        require(msg.sender == i_conceroRouter, InvalidConceroRouter(msg.sender));

        s.ConceroClient storage s_conceroClient = s.conceroClient();

        require(!s_conceroClient.isMessageProcessed[messageId], MessageAlreadyProcessed());
        s_conceroClient.isMessageProcessed[messageId] = true;

        uint8 messageType = _extractMessageType(messageReceipt.payload);

        require(
            s_conceroClient.isRelayerAllowed[messageType][messageReceipt.dstRelayerLib],
            RelayerNotAllowed(messageReceipt.dstRelayerLib)
        );

        _validateMessageReceipt(messageReceipt, validationChecks, messageType);

        _conceroReceive(messageId, messageReceipt);
    }

    function _validateMessageReceipt(
        IConceroRouter.MessageReceipt calldata messageReceipt,
        bool[] calldata validationChecks,
        uint8 messageType
    ) internal view virtual {
        _ensureValidationsWeight(messageReceipt.dstValidatorLibs, validationChecks, messageType);
        _validateSrcChainData(
            messageReceipt.srcChainSelector,
            messageReceipt.srcChainData,
            messageType
        );
    }

    function _ensureValidationsWeight(
        bytes[] memory dstValidatorLibs,
        bool[] calldata validationChecks,
        uint8 messageType
    ) internal view virtual {
        s.ConceroClient storage s_conceroClient = s.conceroClient();
        uint256 totalWeight;

        for (uint256 i; i < dstValidatorLibs.length && i < validationChecks.length; ++i) {
            for (uint256 k; k < dstValidatorLibs.length; ++k) {
                if (i == k) continue;
                require(
                    keccak256(dstValidatorLibs[i]) != keccak256(dstValidatorLibs[k]),
                    ValidatorsConsensusNotReached()
                );
            }

            if (validationChecks[i]) {
                totalWeight += s_conceroClient.validatorWeights[messageType][dstValidatorLibs[i]];
            }
        }

        require(
            totalWeight >= s_conceroClient.requiredWeights[messageType],
            ValidatorsConsensusNotReached()
        );
    }

    function _validateSrcChainData(
        uint24 srcChainSelector,
        bytes memory srcChainData,
        uint8 messageType
    ) internal view virtual {
        require(
            s.conceroClient().isSrcChainDataAllowed[messageType][srcChainSelector][
                keccak256(srcChainData)
            ],
            InvalidSrcChainData()
        );
    }

    function _extractMessageType(bytes memory messagePayload) internal pure returns (uint8) {
        (uint8 messageType, ) = abi.decode(messagePayload, (uint8, bytes));
        require(messageType > 0, ZeroMessageType());
        return messageType;
    }

    function _conceroReceive(
        bytes32 messageId,
        IConceroRouter.MessageReceipt calldata messageReceipt
    ) internal virtual;
}
