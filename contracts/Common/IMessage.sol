pragma solidity 0.8.28;

interface IMessage {
    enum Relayer {
        Symbiosis
    }

    struct TokenAmount {
        address token;
        uint256 amount;
    }

    struct EVMArgs {
        uint32 gasLimit;
    }

    struct Message {
        uint64 srcChainSelector;
        uint64 dstChainSelector;
        address receiver;
        address sender;
        TokenAmount[] tokenAmounts;
        Relayer[] relayers;
        bytes data;
        bytes extraArgs;
    }
}
