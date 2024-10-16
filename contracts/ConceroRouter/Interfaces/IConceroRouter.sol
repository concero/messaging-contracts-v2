pragma solidity 0.8.20;

interface IConceroRouter {
    //////////////////////////
    /////TYPES DEFINITIONS////
    //////////////////////////

    enum Relayer {
        Symbiosis
    }

    struct MessageRequest {
        address feeToken;
        Message message;
    }

    struct Message {
        uint64 dstChainSelector;
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
    event ReportProcessed(
        bytes32 indexed requestId,
        bytes result,
        bytes error,
        bytes metadata,
        bytes offchainMetadata
    );
}
