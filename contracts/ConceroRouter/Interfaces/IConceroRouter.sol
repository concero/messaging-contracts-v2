pragma solidity 0.8.28;

import {IMessage} from "../../Common/IMessage.sol";

interface IConceroRouter is IMessage {
    //////////////////////////
    /////TYPES DEFINITIONS////
    //////////////////////////

    struct MessageRequest {
        address feeToken;
        uint64 dstChainSelector;
        address receiver;
        TokenAmount[] tokenAmounts;
        Relayer[] relayers;
        bytes data;
        bytes extraArgs;
    }

    struct ClfDonReportSubmission {
        bytes32[3] context;
        bytes report;
        bytes32[] rs;
        bytes32[] ss;
        bytes rawVs;
    }

    //////////////////////
    ////////EVENTS////////
    //////////////////////

    event ConceroMessageSent(bytes32 indexed id, Message message);
    event ConceroMessageReceived(bytes32 indexed id, Message message);
}
