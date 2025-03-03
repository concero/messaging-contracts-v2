// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

event ConceroMessageSent(
    // @dev TODO: check if it needed
    bytes32 indexed internalMessageConfig,
    bytes32 indexed messageId,
    bytes dstChainData,
    bytes message
);
event ConceroMessageReceived(bytes32 indexed id);
event ConceroMessageDelivered(bytes32 indexed id);
event OperatorFeeWithdrawn(address indexed operator, uint256 amount);

interface IConceroRouter {
    function conceroSend(
        bytes32 config,
        bytes calldata dstChainData,
        bytes calldata message
    ) external payable returns (bytes32 messageId);
}
