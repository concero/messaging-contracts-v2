// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {BaseModule} from "./BaseModule.sol";
import {OperatorModule} from "./OperatorModule.sol";
import {MessageModule} from "./MessageModule.sol";
import {StorageModule} from "./StorageModule.sol";
import {OwnerModule} from "./OwnerModule.sol";
import {IConceroRouter} from "../Interfaces/IConceroRouter.sol";

contract ConceroRouter is
    IConceroRouter,
    OperatorModule,
    MessageModule,
    StorageModule,
    OwnerModule
{
    constructor(uint24 chainSelector, address USDC) BaseModule(chainSelector, USDC) {}

    /* EXTERNAL FUNCTIONS */
    receive() external payable {}
    fallback() external payable {}
}
