// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "./IConceroRouter.sol";

interface IRelayerLib {
    error InvalidRelayer();

    function getFee(
        IConceroRouter.MessageRequest calldata messageRequest
    ) external view returns (uint256);

    function getDstLib(uint24 dstChainSelector) external view returns (bytes memory);

    function validate(bytes calldata messageReceipt, address s_relayer) external;
}
