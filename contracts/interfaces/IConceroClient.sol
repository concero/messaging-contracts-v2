// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "./IConceroRouter.sol";

interface IConceroClient {
    error InvalidDstChainData();

    //utils lib
    //todo: check all errors if they need to be here.
    error NotAContract(address target);

    function conceroReceive(
        bytes32 messageId,
        IConceroRouter.MessageReceipt calldata messageReceipt,
        bool[] calldata validationChecks
    ) external;
}
