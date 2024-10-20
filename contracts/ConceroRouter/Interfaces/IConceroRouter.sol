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

    struct ClfDonReport {
        bytes32[3] calldata context;
        bytes calldata data;
        bytes32[] calldata rs;
        bytes32[] calldata ss;
        bytes calldata rawVs;
    }

    //////////////////////
    ////////EVENTS////////
    //////////////////////

    event ConceroMessage(bytes32 indexed id, Message message);
}
