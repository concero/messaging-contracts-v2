pragma solidity 0.8.20;

interface IConceroMessage {
    //////////////////////////
    /////TYPES DEFINITIONS////
    //////////////////////////

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

    enum Relayer {
        Symbiosis
    }

    struct EVMArgs {
        uint32 gasLimit;
    }

    struct ChainSelectors {
        uint64 arbitrumChainSelector;
        uint64 baseChainSelector;
        uint64 polygonChainSelector;
        uint64 avalancheChainSelector;
        uint64 optimismChainSelector;
    }

    //////////////////////
    ////////EVENTS////////
    //////////////////////

    event ConceroMessage(bytes32 id, Message message);
}
