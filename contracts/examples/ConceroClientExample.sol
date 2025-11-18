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

    constructor(address conceroRouter, address relayerLib) ConceroClientBase(conceroRouter) {
        i_relayerLib = relayerLib;

        _setIsRelayerAllowed(relayerLib, true);
    }

    function _conceroReceive(bytes calldata messageReceipt) internal override {
        emit MessageReceived(keccak256(messageReceipt), messageReceipt.payload());
    }

    function _validateMessageSubmission(
        bool[] calldata validationChecks,
        address[] calldata validatorLibs
    ) internal view override {}

    function sendConceroMessage(address receiver, uint24 dstChainSelector) external payable {
        IConceroRouter(i_conceroRouter).conceroSend{value: msg.value}(
            _buildMessageRequest(receiver, dstChainSelector)
        );
    }

    function getMessageFee(
        address receiver,
        uint24 dstChainSelector
    ) external view returns (uint256) {
        return
            IConceroRouter(i_conceroRouter).getMessageFee(
                _buildMessageRequest(receiver, dstChainSelector)
            );
    }

    function _buildMessageRequest(
        address receiver,
        uint24 dstChainSelector
    ) internal view returns (IConceroRouter.MessageRequest memory) {
        return
            IConceroRouter.MessageRequest({
                dstChainSelector: dstChainSelector,
                srcBlockConfirmations: 0,
                feeToken: address(0),
                relayerLib: i_relayerLib,
                validatorLibs: new address[](0),
                validatorConfigs: new bytes[](0),
                relayerConfig: new bytes(1),
                dstChainData: MessageCodec.encodeEvmDstChainData(receiver, 300_000),
                payload: "Hello world!"
            });
    }
}
