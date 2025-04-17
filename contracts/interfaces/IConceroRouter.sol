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

interface IConceroRouter {
    function conceroSend(
        uint24 dstChainSelector,
        bool shouldFinaliseSrc,
        address feeToken,
        ConceroTypes.EvmDstChainData memory dstChainData,
        bytes calldata message
    ) external payable returns (bytes32 messageId);

    function getMessageFee(
        uint24 dstChainSelector,
        bool shouldFinaliseSrc,
        address feeToken,
        ConceroTypes.EvmDstChainData memory dstChainData
    ) external view returns (uint256);
}
