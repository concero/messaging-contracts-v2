//// SPDX-License-Identifier: UNLICENSED
///**
// * @title Security Reporting
// * @notice If you discover any security vulnerabilities, please report them responsibly.
// * @contact email: security@concero.io
// */
//pragma solidity 0.8.28;
//
//import {ConceroRouter} from "../../../contracts/ConceroRouter/ConceroRouter.sol";
//
//contract ConceroRouterInvariants is ConceroRouter {
//    mapping(bytes32 messageId => bool isProcessed) internal isMessageProcessed;
//    bool internal isUniqMessageId = true;
//
//    function conceroSendFuzz(IConceroRouter.MessageRequest memory mr) public payable {
//        uint256 fee = getMessageFee(mr);
//        bytes32 id = conceroSend{value: fee}(mr);
//
//        if (isMessageProcessed[id]) {
//            isUniqMessageId = false;
//            return;
//        }
//
//        isMessageProcessed[id] = true;
//    }
//
//    function isInvariantHolds() public view returns (bool) {
//        return isUniqMessageId;
//    }
//}
