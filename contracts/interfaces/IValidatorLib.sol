// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroTypes} from "../ConceroClient/ConceroTypes.sol";

error InvalidChainSelector();

interface IValidatorLib {
    function isValid(
        bytes32 messageId,
        ConceroTypes.MessageRequest calldata message,
        bytes calldata validation
    ) external view returns (bool);

    function getFee(
        ConceroTypes.MessageRequest calldata message,
        ConceroTypes.MessageHeader calldata messageHeader
    ) external view returns (uint256);

    function getDstLib(uint24 dstChainSelector) external view returns (bytes memory);
}
