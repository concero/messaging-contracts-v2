pragma solidity 0.8.20;

interface IConceroMessenger {
    //////////////////////////
    /////TYPES DEFINITIONS////
    //////////////////////////

    enum Relayer {
        Symbiosis
    }

    struct Message {
        uint64 dstChainSelector;
        address feeToken;
        address receiver;
        TokenAmount[] tokenAmounts;
        Relayer[] relayers;
        bytes data;
        bytes extraArgs;
    }

    struct TokenAmount {
        address token;
        uint256 amount;
    }

    struct EVMArgs {
        uint32 gasLimit;
    }

    //////////////////////
    ////////EVENTS////////
    //////////////////////

    event ConceroMessage(bytes32 id, Message message);
}
