pragma solidity 0.8.20;

interface IConceroMessage {
    //////////////////////////
    /////TYPES DEFINITIONS////
    //////////////////////////

    struct Message {
        uint64 dstChainSelector;
        TokenAmount[] tokensAmounts;
        Relayer[] relayers;
        bytes feeToken;
        bytes receiver;
        bytes data;
        bytes extraArgs;
    }

    struct TokenAmount {
        address token;
        uint256 amount;
    }

    enum Relayer {
        Symbiosis
    }

    struct EVMArgs {
        uint32 gasLimit;
    }

    //////////////////////
    ////////EVENTS////////
    //////////////////////

    event ConceroMessage(bytes32 id, Message message);
}
