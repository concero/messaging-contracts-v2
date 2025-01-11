// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroOwnable} from "./ConceroOwnable.sol";

error OnlyAllowedOperator();

contract OperatorCompatible is ConceroOwnable {
    mapping(address => bool) public s_isAllowedOperator;

    constructor() ConceroOwnable() {}

    modifier onlyAllowedOperator() {
        require(s_isAllowedOperator[msg.sender], OnlyAllowedOperator());
        _;
    }

    function registerOperator(address operator) external payable onlyOwner {
        s_isAllowedOperator[operator] = true;
    }

    function deregisterOperator(address operator) external payable onlyOwner {
        s_isAllowedOperator[operator] = false;
    }
}
