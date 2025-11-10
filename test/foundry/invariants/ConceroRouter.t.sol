//// SPDX-License-Identifier: UNLICENSED
///**
// * @title Security Reporting
// * @notice If you discover any security vulnerabilities, please report them responsibly.
// * @contact email: security@concero.io
// */
//pragma solidity 0.8.28;
//
//import {CommonErrors} from "contracts/common/CommonErrors.sol";
//import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
//import {ConceroRouterTest} from "../ConceroRouter/base/ConceroRouterTest.sol";
//
//contract ConceroRouterInvariants is ConceroRouterTest {
//
//    function
//
//
//    function invariant_uniqId(IConceroRouter.MessageRequest calldata messageRequest) public {
//        uint256 fee = s_conceroRouter.getMessageFee(messageRequest);
//        bytes32 messageId = s_conceroRouter.conceroSend(messageRequest);
//
//        assert(!isMessageProcessed[messageId]);
//
//        isMessageProcessed[messageId] = true;
//    }
//}
