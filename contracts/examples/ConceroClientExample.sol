//// SPDX-License-Identifier: MIT
///**
// * @title Security Reporting
// * @notice If you discover any security vulnerabilities, please report them responsibly.
// * @contact email: security@concero.io
// */
//pragma solidity 0.8.28;
//
//import {IConceroRouter} from "../interfaces/IConceroRouter.sol";
//import {ConceroClient} from "./ConceroClient.sol";
//import {ConceroTypes} from "./ConceroTypes.sol";
//
//contract ConceroClientExample is ConceroClient {
//    event MessageReceived(bytes32 messageId, bytes message);
//
//    constructor(address conceroRouter) ConceroClient(conceroRouter) {}
//
//    function _conceroReceive(
//        bytes32 messageId,
//        uint24 srcChainSelector,
//        bytes calldata sender,
//        bytes calldata message
//    ) internal override {
//        emit MessageReceived(messageId, message);
//    }
//
//    function sendConceroMessage(address receiver) external payable returns (bytes32 messageId) {
//        messageId = IConceroRouter(i_conceroRouter).conceroSend{value: msg.value}(
//            137,
//            false,
//            address(0),
//            ConceroTypes.EvmDstChainData({receiver: receiver, gasLimit: 100_000}),
//            "Hello from Concero!"
//        );
//    }
//
//    function sendConceroMessage(
//        address receiver,
//        uint24 dstChainSelector
//    ) external payable returns (bytes32 messageId) {
//        messageId = IConceroRouter(i_conceroRouter).conceroSend{value: msg.value}(
//            dstChainSelector,
//            false,
//            address(0),
//            ConceroTypes.EvmDstChainData({receiver: receiver, gasLimit: 100_000}),
//            "Hello from Concero!"
//        );
//    }
//}
