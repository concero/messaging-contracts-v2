// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroTypes} from "../ConceroClient/ConceroTypes.sol";

event ConceroMessageSent(
    bytes32 indexed messageId,
    uint8 version,
    bool shouldFinaliseSrc,
    uint24 dstChainSelector,
    bytes dstChainData,
    address sender,
    bytes message
);

event ConceroMessageReceived(bytes32 indexed id);
event ConceroMessageDelivered(bytes32 indexed id);
event OperatorFeeWithdrawn(address indexed operator, uint256 amount);
event MessageReorgDetected(bytes32 indexed txHash, uint24 indexed srcChainSelector);

interface IConceroRouter {
    /**
     * @notice Concero allows you to send messages from one blockchain
     *         to another using the `conceroSend` function. This enables
     *         cross-chain interactions for a variety of use cases:
     *         token transfers, governance actions, or any custom
     *         cross-chain operations.
     *
     * @param dstChainSelector   Identifier of the destination chain.
     * @param shouldFinaliseSrc  Flag for source‐chain finality.
     * @param feeToken           Token used to pay message fees.
     * @param dstChainData       Struct containing execution parameters
     *                           for the destination chain.
     * @param message            Payload of the message to be sent to
     *                           the destination chain.
     */
    function conceroSend(
        uint24 dstChainSelector,
        bool shouldFinaliseSrc,
        address feeToken,
        ConceroTypes.EvmDstChainData memory dstChainData,
        bytes calldata message
    ) external payable returns (bytes32 messageId);

    /**
     * @notice Before sending a message, you must call getMessageFee.
     *         If you choose to pay fees in the native token, pass the
     *         returned value as msg.value.
     *
     * @param dstChainSelector   Identifier of the destination chain.
     * @param shouldFinaliseSrc  Flag for source‐chain finality.
     * @param feeToken           Token used to pay message fees.
     * @param dstChainData       Struct containing execution parameters
     *                           for the destination chain.
     */
    function getMessageFee(
        uint24 dstChainSelector,
        bool shouldFinaliseSrc,
        address feeToken,
        ConceroTypes.EvmDstChainData memory dstChainData
    ) external view returns (uint256);
}
