// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Storage as s} from "./libraries/Storage.sol";

import {Base} from "./modules/Base.sol";
import {Operator} from "./modules/Operator.sol";
import {Message} from "./modules/Message.sol";
import {Owner} from "./modules/Owner.sol";

import {IConceroRouter} from "../interfaces/IConceroRouter.sol";

contract ConceroRouter is IConceroRouter, Operator, Message, Owner {
    constructor(
        uint24 chainSelector,
        address feedUpdater,
        address conceroVerifier,
        uint64 conceroVerifierSubId,
        address[4] memory clfSigners
    )
        Message(conceroVerifier, conceroVerifierSubId, clfSigners)
        Base(chainSelector)
        Owner(feedUpdater)
    {}

    receive() external payable {}

    fallback() external payable {}
}
