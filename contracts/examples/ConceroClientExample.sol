// SPDX-License-Identifier: MIT
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IConceroRouter} from "../interfaces/IConceroRouter.sol";
import {ConceroClientBase} from "../ConceroClient/ConceroClientBase.sol";
import {MessageCodec} from "../common/libraries/MessageCodec.sol";

contract ConceroClientExample is ConceroClientBase {
    using MessageCodec for bytes;

    event MessageReceived(bytes32 messageId, bytes message);

    address internal immutable i_relayerLib;
    address internal immutable i_validatorLib;

    constructor(
        address conceroRouter,
        address relayerLib,
        address validatorLib
    ) ConceroClientBase(conceroRouter) {
        i_relayerLib = relayerLib;
        i_validatorLib = validatorLib;

        _setIsRelayerLibAllowed(relayerLib, true);
    }

    function _conceroReceive(bytes calldata messageReceipt) internal override {
        emit MessageReceived(keccak256(messageReceipt), messageReceipt.payload());
    }

    function _validateMessageSubmission(
        bool[] calldata validationChecks,
        address[] calldata validatorLibs
    ) internal view override {}

    function sendConceroMessage(
        address receiver,
        uint24 dstChainSelector,
        uint64 blockConfirmations
    ) external payable {
        IConceroRouter(i_conceroRouter).conceroSend{value: msg.value}(
            _buildMessageRequest(receiver, dstChainSelector, blockConfirmations, "")
        );
    }

    function sendConceroMessage(
        address receiver,
        uint24 dstChainSelector,
        uint64 blockConfirmations,
        bytes calldata payload
    ) external payable {
        IConceroRouter(i_conceroRouter).conceroSend{value: msg.value}(
            _buildMessageRequest(receiver, dstChainSelector, blockConfirmations, payload)
        );
    }

    function getMessageFee(
        address receiver,
        uint24 dstChainSelector
    ) external view returns (uint256) {
        return
            IConceroRouter(i_conceroRouter).getMessageFee(
                _buildMessageRequest(receiver, dstChainSelector, 0, "")
            );
    }

    function _buildMessageRequest(
        address receiver,
        uint24 dstChainSelector,
        uint64 blockConfirmations,
        bytes memory payload
    ) internal view returns (IConceroRouter.MessageRequest memory) {
        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = i_validatorLib;

        return
            IConceroRouter.MessageRequest({
                dstChainSelector: dstChainSelector,
                srcBlockConfirmations: blockConfirmations,
                feeToken: address(0),
                relayerLib: i_relayerLib,
                validatorLibs: validatorLibs,
                validatorConfigs: new bytes[](1),
                relayerConfig: new bytes(1),
                dstChainData: MessageCodec.encodeEvmDstChainData(receiver, 300_000),
                payload: payload
            });
    }
}
