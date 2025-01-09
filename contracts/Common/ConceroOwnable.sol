// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

contract ConceroOwnable {
    error OnlyOwner();

    address internal immutable i_owner;

    constructor(address owner) {
        i_owner = owner;
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, OnlyOwner());
        _;
    }
}
