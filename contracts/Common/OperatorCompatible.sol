//// SPDX-License-Identifier: UNLICENSED
//pragma solidity 0.8.28;
//
//import "./ConceroOwnable.sol";
//
//error OnlyAllowedOperator();
//
//contract OperatorCompatible is ConceroOwnable {
//    modifier onlyAllowedOperator() {
//        require(s_isAllowedOperator[msg.sender], OnlyAllowedOperator());
//        _;
//    }
//
//    function registerOperator(address operator) external payable onlyOwner {
//        s_isAllowedOperator[operator] = true;
//    }
//
//    function deregisterOperator(address operator) external payable onlyOwner {
//        s_isAllowedOperator[operator] = false;
//    }
//}
