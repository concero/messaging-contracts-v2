pragma solidity 0.8.28;

import {ConceroOwnable} from "./ConceroOwnable.sol";

error OnlyAllowedOperator();

contract OperatorCompatible is ConceroOwnable {
    mapping(address => bool) public s_isAllowedOperator;

    constructor(address owner) ConceroOwnable(owner) {}

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
