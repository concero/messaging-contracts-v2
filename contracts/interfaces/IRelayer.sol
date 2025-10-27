// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "./IConceroRouter.sol";

interface IRelayer {
    error MessageSubmissionAlreadyReceived(bytes32 messageId, bytes32 messageSubmissionHash);
    error InvalidReceiver();
    error InvalidDstChainSelector(uint24 received, uint24 expexted);

    event RelayerFeeWithdrawn(address indexed, address indexed token, uint256 amount);

    /**
     * @notice Submits a message report, verifies the signatures, and processes the report data.
     */
    function submitMessage(
        bytes32 messageId,
        IConceroRouter.MessageReceipt calldata messageReceipt,
        bytes[] calldata validations
    ) external;
}
