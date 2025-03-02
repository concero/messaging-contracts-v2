// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonErrors} from "./CommonErrors.sol";

abstract contract ConceroOwnable {
    address public immutable i_owner;

    modifier onlyOwner() {
        require(msg.sender == i_owner, CommonErrors.NotOwner());
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }
}
