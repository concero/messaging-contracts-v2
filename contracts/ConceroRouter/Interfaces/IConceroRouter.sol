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

    //////////////////////
    ////////EVENTS////////
    //////////////////////

    event NewMessage(bytes32 indexed id, Message message);
    event ReportProcessed(
        bytes32 indexed requestId,
        bytes result,
        bytes error,
        bytes metadata,
        bytes offchainMetadata
    );
}
