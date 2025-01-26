// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Base} from "./modules/Base.sol";
import {Operator} from "./modules/Operator.sol";
import {Message} from "./modules/Message.sol";
import {GenericStorage} from "./modules/GenericStorage.sol";
import {Owner} from "./modules/Owner.sol";
import {IConceroRouter} from "../interfaces/IConceroRouter.sol";

contract ConceroRouter is IConceroRouter, Operator, Message, GenericStorage, Owner {
    constructor(uint24 chainSelector, address USDC) Base(chainSelector, USDC) {}

    receive() external payable {}

    fallback() external payable {}
}
